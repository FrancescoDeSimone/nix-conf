#!/usr/bin/env python3
"""deemix-arr: Torznab indexer + qBittorrent-compatible download client
backed by a native deemix webui. Lets stock Lidarr (no plugin system)
search Deezer and download through deemix. Stdlib only."""

import argparse
import difflib
import hashlib
import http.cookiejar
import json
import os
import re
import shutil
import sys
import threading
import time
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from xml.sax.saxutils import escape

VERSION = "0.1.0"
POLL_SECS = 5
MISS_LIMIT = 60

jobs = {}
jobs_lock = threading.Lock()
cfg = {}


def log(*a):
    print("[deemix-arr]", *a, flush=True)


class Deemix:
    def __init__(self, base):
        self.base = base.rstrip("/")
        self.cj = http.cookiejar.CookieJar()
        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(self.cj))
        self.lock = threading.Lock()
        self.bitrate = None
        self.flac = False

    def _req(self, method, path, data=None, query=None):
        url = self.base + path
        if query:
            url += "?" + urllib.parse.urlencode(query)
        body = json.dumps(data).encode() if data is not None else None
        req = urllib.request.Request(url, data=body, method=method,
                                     headers={"Content-Type": "application/json"})
        with self.lock:
            try:
                with self.opener.open(req, timeout=60) as r:
                    return json.loads(r.read().decode() or "{}")
            except urllib.error.HTTPError as e:
                try:
                    return json.loads(e.read().decode() or "{}")
                except Exception:
                    return {}

    def get(self, path, query=None):
        return self._req("GET", path, None, query)

    def post(self, path, data=None, query=None):
        return self._req("POST", path, data or {}, query)

    def ensure_login(self):
        try:
            c = self.get("/api/connect")
        except Exception as e:
            return False, f"connect failed: {e}"
        if (c.get("currentUser") or {}).get("id"):
            return True, ""
        arl = ((c.get("singleUser") or {}).get("arl")
               or (c.get("singleuser") or {}).get("arl"))
        if not arl:
            return False, "no ARL available for login"
        try:
            r = self.post("/api/loginArl", {"arl": arl})
        except Exception as e:
            return False, f"loginArl failed: {e}"
        if r.get("status") in (1, 2, 3):
            return True, ""
        return False, f"loginArl status={r.get('status')}"

    def load_caps(self):
        try:
            s = self.get("/api/getSettings")
            self.bitrate = (s.get("settings") or {}).get("maxBitrate", 1)
        except Exception:
            self.bitrate = 1
        self.flac = (self.bitrate == 9)

    def search_albums(self, term, nb=20):
        try:
            r = self.get("/api/search", {"term": term, "type": "album",
                                         "start": 0, "nb": nb})
        except Exception:
            return []
        return r.get("data") or []

    def add_album(self, album_id):
        ok, err = self.ensure_login()
        if not ok:
            return None, "", "", err
        url = f"https://www.deezer.com/album/{album_id}"
        try:
            r = self.post("/api/addToQueue", {"url": url})
        except Exception as e:
            return None, "", "", f"addToQueue failed: {e}"
        if not r.get("result"):
            if (r.get("errid") or "") == "NotLoggedIn":
                self.cj.clear()
                ok, err = self.ensure_login()
                if not ok:
                    return None, "", "", err
                try:
                    r = self.post("/api/addToQueue", {"url": url})
                except Exception as e:
                    return None, "", "", f"addToQueue failed: {e}"
            if not r.get("result"):
                return None, "", "", f"addToQueue: {r.get('errid')}"
        obj = (r.get("data") or {}).get("obj") or []
        if isinstance(obj, dict):
            obj = [obj]
        first = obj[0] if obj else {}
        if not first.get("uuid"):
            return (None, "", "",
                    f"deemix queued nothing for album {album_id} "
                    "(unavailable in this region?)")
        return (first.get("uuid"), first.get("artist") or "",
                first.get("title") or "", "")

    def queue(self):
        try:
            return self.get("/api/getQueue")
        except Exception:
            return {}

    def cancel(self, uuid):
        try:
            self.post("/api/removeFromQueue", None, {"uuid": uuid})
        except Exception:
            pass


dz = None


def fake_hash(kind, did):
    return hashlib.sha1(f"deemix-arr:{kind}:{did}".encode()).hexdigest()


def safe_name(s):
    s = re.sub(r"[/\\]+", "-", s or "")
    s = re.sub(r"\s+", " ", s).strip()
    return s[:150] or "unknown"


def torznab_date(s):
    try:
        t = time.strptime((s or "")[:10], "%Y-%m-%d")
        return time.strftime("%a, %d %b %Y %H:%M:%S +0000", t)
    except Exception:
        return time.strftime("%a, %d %b %Y %H:%M:%S +0000", time.gmtime())


def album_size(item):
    n = item.get("nb_tracks") or 10
    try:
        n = int(n)
    except Exception:
        n = 10
    per = 35 * 1024 * 1024 if dz.flac else 10 * 1024 * 1024
    return max(n, 1) * per


def magnet_for(item):
    aid = str(item.get("id"))
    artist = (item.get("artist") or {}).get("name", "")
    title = item.get("title", "")
    dn = urllib.parse.quote(f"{artist} - {title} [deemix:album:{aid}]")
    h = fake_hash("album", aid)
    return (f"magnet:?xt=urn:btih:{h}&dn={dn}"
            f"&x-deemix-type=album&x-deemix-id={aid}"), h


def torznab_caps():
    return ("<?xml version=\"1.0\" encoding=\"UTF-8\"?><caps>"
            "<server title=\"deemix-arr\" version=\"" + VERSION + "\"/>"
            "<limits max=\"100\" default=\"50\"/>"
            "<registration available=\"no\"/>"
            "<searching>"
            "<search available=\"yes\" supportedParams=\"q\"/>"
            "<music-search available=\"yes\" supportedParams=\"q,artist,album,year\"/>"
            "</searching>"
            "<categories>"
            "<category id=\"3000\" name=\"Audio\">"
            "<subcat id=\"3010\" name=\"Audio/MP3\"/>"
            "<subcat id=\"3040\" name=\"Audio/Lossless\"/>"
            "</category></categories></caps>")


def torznab_search(params):
    artist = params.get("artist", "")
    album = params.get("album", "")
    q = params.get("q", "")
    term = " ".join(x for x in (artist, album, q) if x).strip()
    if not term:
        return ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                "<rss version=\"2.0\" xmlns:torznab=\"http://torznab.com/schemas/2015/feed\">"
                "<channel><title>deemix-arr</title></channel></rss>")
    items = []
    for a in dz.search_albums(term):
        try:
            aid = str(a.get("id"))
            aname = (a.get("artist") or {}).get("name", "")
            atitle = a.get("title", "")
            genre = ((a.get("genres") or {}).get("data") or [{}])[0].get("name", "")
            year = (a.get("release_date") or "")[:4]
            magnet, h = magnet_for(a)
            size = album_size(a)
            cat = "3040" if dz.flac else "3010"
            title = escape(f"{aname} - {atitle}" + (f" ({year})" if year else ""))
            items.append(
                "<item><title>" + title + "</title>"
                "<guid>" + escape(magnet) + "</guid>"
                "<link>" + escape(magnet) + "</link>"
                "<pubDate>" + torznab_date(a.get("release_date")) + "</pubDate>"
                "<category>3000</category><category>" + cat + "</category>"
                "<enclosure url=\"" + escape(magnet) + "\" length=\"" + str(size) +
                "\" type=\"application/x-bittorrent\"/>"
                "<torznab:attr name=\"category\" value=\"3000\"/>"
                "<torznab:attr name=\"category\" value=\"" + cat + "\"/>"
                "<torznab:attr name=\"size\" value=\"" + str(size) + "\"/>"
                "<torznab:attr name=\"album\" value=\"" + escape(atitle) + "\"/>"
                "<torznab:attr name=\"artist\" value=\"" + escape(aname) + "\"/>"
                + ("<torznab:attr name=\"genre\" value=\"" + escape(genre) + "\"/>" if genre else "")
                + ("<torznab:attr name=\"year\" value=\"" + escape(year) + "\"/>" if year else "") +
                "<torznab:attr name=\"seeders\" value=\"100\"/>"
                "<torznab:attr name=\"peers\" value=\"50\"/>"
                "<torznab:attr name=\"downloadvolumefactor\" value=\"0\"/>"
                "<torznab:attr name=\"uploadvolumefactor\" value=\"1\"/>"
                "<torznab:attr name=\"minimumratio\" value=\"0\"/>"
                "</item>")
        except Exception as e:
            log("search item failed:", e)
    return ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
            "<rss version=\"2.0\" xmlns:torznab=\"http://torznab.com/schemas/2015/feed\">"
            "<channel><title>deemix-arr</title>" + "".join(items) + "</channel></rss>")


def parse_magnet(uri):
    try:
        q = urllib.parse.urlparse(uri).query
        p = urllib.parse.parse_qs(q)
        did = (p.get("x-deemix-id") or [None])[0]
        typ = (p.get("x-deemix-type") or ["album"])[0]
        if not did:
            m = re.search(r"deemix:(album|track):(\d+)", p.get("dn", [""])[0])
            if m:
                typ, did = m.group(1), m.group(2)
        if did:
            return typ, did
    except Exception:
        pass
    return None, None


def state_path():
    return os.path.join(cfg["state_dir"], "state.json")


def save_state():
    try:
        tmp = state_path() + ".tmp"
        with open(tmp, "w") as f:
            json.dump(jobs, f)
        os.replace(tmp, state_path())
    except Exception as e:
        log("state save failed:", e)


def load_state():
    try:
        with open(state_path()) as f:
            data = json.load(f)
        with jobs_lock:
            jobs.update(data)
        log(f"restored {len(data)} jobs")
    except FileNotFoundError:
        pass
    except Exception as e:
        log("state load failed:", e)


def predict_dir(artist, album):
    return os.path.join(cfg["music_dir"], safe_name(artist), safe_name(album))


def locate_album_dir(artist, album):
    pred = predict_dir(artist, album)
    if os.path.isdir(pred):
        return pred
    try:
        cands = []
        now = time.time()
        for entry in os.listdir(cfg["music_dir"]):
            full = os.path.join(cfg["music_dir"], entry)
            if not os.path.isdir(full):
                continue
            try:
                age = now - os.path.getmtime(full)
            except OSError:
                continue
            if age > 3600:
                continue
            ratio = difflib.SequenceMatcher(
                None, entry.casefold(),
                artist.casefold()).ratio()
            cands.append((ratio, age, full))
        cands.sort(key=lambda x: (-x[0], x[1]))
        if cands and cands[0][0] > 0.5:
            adir = cands[0][2]
            subs = [os.path.join(adir, s) for s in os.listdir(adir)
                    if os.path.isdir(os.path.join(adir, s))]
            if not subs:
                return None
            subs.sort(key=lambda s: difflib.SequenceMatcher(
                None, os.path.basename(s).casefold(),
                album.casefold()).ratio(), reverse=True)
            return subs[0]
    except Exception as e:
        log("locate failed:", e)
    return None


def poller():
    while True:
        time.sleep(POLL_SECS)
        try:
            tick()
        except Exception as e:
            log("tick failed:", e)


def tick():
    with jobs_lock:
        active = [h for h, j in jobs.items()
                  if j.get("status") in ("queued", "downloading")]
    if not active:
        return
    q = dz.queue().get("queue") or {}
    by_uuid = {}
    for uuid, item in q.items():
        by_uuid[uuid] = item
    changed = False
    with jobs_lock:
        for h in active:
            j = jobs[h]
            item = by_uuid.get(j.get("uuid") or "")
            if item is None:
                j["misses"] = j.get("misses", 0) + 1
                if j["misses"] >= MISS_LIMIT:
                    j["status"] = "error"
                    changed = True
                continue
            j["misses"] = 0
            st = item.get("status", "")
            j["progress"] = float(item.get("progress") or 0) / 100.0
            if st in ("completed", "withErrors"):
                done = int(item.get("downloaded") or 0)
                if done <= 0:
                    j["status"] = "error"
                else:
                    finish_job(h, j)
                changed = True
            elif st == "failed":
                j["status"] = "error"
                changed = True
            elif j["status"] == "queued" and st == "downloading":
                j["status"] = "downloading"
                changed = True
    if changed:
        save_state()


def finish_job(h, j):
    src = locate_album_dir(j["artist"], j["album"])
    if not src:
        log(f"completed but dir not found: {j['artist']} - {j['album']}")
        j["status"] = "error"
        return
    name = safe_name(f"{j['artist']} - {j['album']}")
    dest = os.path.join(cfg["staging_dir"], name)
    try:
        if os.path.exists(dest):
            shutil.rmtree(dest)
        shutil.move(src, dest)
        os.chmod(dest, 0o775)
        j["save_path"] = cfg["staging_dir"]
        j["name"] = name
        j["status"] = "done"
        j["progress"] = 1.0
        log(f"staged {h}: {dest}")
    except Exception as e:
        log(f"stage failed {h}: {e}")
        j["status"] = "error"


def qstate(j):
    st = j.get("status")
    if st == "done":
        return "uploading"
    if st == "error":
        return "error"
    if j.get("paused"):
        return "pausedDL"
    if st == "downloading":
        return "downloading"
    return "queuedDL"


def job_info(h, j):
    return {
        "hash": h,
        "name": j.get("name") or f"{j['artist']} - {j['album']}",
        "magnet_uri": j.get("magnet", ""),
        "size": j.get("size", 0),
        "progress": j.get("progress", 0.0),
        "state": qstate(j),
        "save_path": j.get("save_path") or predict_dir(j["artist"], j["album"]),
        "category": j.get("category", ""),
        "num_seeds": 100,
        "num_leechs": 50,
        "ratio": 0,
        "eta": 0 if j.get("status") == "done" else 86400,
        "completion_on": 0,
        "content_path": os.path.join(
            j.get("save_path") or predict_dir(j["artist"], j["album"]),
            j.get("name") or f"{j['artist']} - {j['album']}"),
    }


class Handler(BaseHTTPRequestHandler):
    server_version = "deemix-arr/" + VERSION

    def log_message(self, *a):
        pass

    def _send(self, code, body, ctype="application/json"):
        if isinstance(body, str):
            body = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _form(self):
        ln = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(ln).decode("utf-8", "replace") if ln else ""
        ctype = self.headers.get("Content-Type") or ""
        if "application/json" in ctype:
            try:
                return json.loads(raw or "{}")
            except Exception:
                return {}
        return {k: v[0] for k, v in urllib.parse.parse_qs(raw).items()}

    def _qs(self):
        return {k: v[0] for k, v in urllib.parse.parse_qs(
            urllib.parse.urlparse(self.path).query).items()}

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api":
            q = self._qs()
            if q.get("apikey", "") != cfg["api_key"]:
                self._send(401, "invalid apikey", "text/plain")
                return
            t = q.get("t", "")
            if t == "caps":
                self._send(200, torznab_caps(), "application/xml")
            elif t in ("search", "music"):
                self._send(200, torznab_search(q), "application/xml")
            else:
                self._send(400, "unsupported t", "text/plain")
            return
        if parsed.path == "/api/v2/app/version":
            self._send(200, "4.6.0", "text/plain")
            return
        if parsed.path == "/api/v2/torrents/info":
            q = self._qs()
            hashes = set((q.get("hashes") or "").lower().split("|")) - {""}
            with jobs_lock:
                out = [job_info(h, j) for h, j in jobs.items()
                       if not hashes or h in hashes]
            self._send(200, json.dumps(out))
            return
        if parsed.path == "/api/v2/sync/maindata":
            with jobs_lock:
                torr = {h: job_info(h, j) for h, j in jobs.items()}
            self._send(200, json.dumps({"rid": 1, "full_update": True,
                                        "torrents": torr, "categories": {}}))
            return
        self._send(404, "not found", "text/plain")

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api/v2/auth/login":
            f = self._form()
            if (f.get("username") == cfg["qb_user"]
                    and f.get("password") == cfg["qb_pass"]):
                self.send_response(200)
                self.send_header("Set-Cookie", "SID=deemix-arr; Path=/")
                self.send_header("Content-Type", "text/plain")
                body = b"Ok."
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
            else:
                self._send(403, "Fails.", "text/plain")
            return
        if parsed.path == "/api/v2/torrents/add":
            f = self._form()
            urls = (f.get("urls") or "").replace("\n", "|").split("|")
            savepath = f.get("savepath", "")
            category = f.get("category", "")
            paused = f.get("paused", "false") == "true"
            added = []
            with jobs_lock:
                for u in urls:
                    u = u.strip()
                    if not u.startswith("magnet:"):
                        continue
                    typ, did = parse_magnet(u)
                    if not did:
                        continue
                    h = fake_hash(typ, did)
                    if h not in jobs:
                        jobs[h] = {"type": typ, "deemix_id": did,
                                   "magnet": u, "artist": "", "album": "",
                                   "name": "", "size": 0, "progress": 0.0,
                                   "status": "queued", "paused": paused,
                                   "category": category,
                                   "savepath_hint": savepath,
                                   "uuid": "", "misses": 0}
                    added.append(h)
            for h in added:
                self._submit(h)
            save_state()
            self._send(200, "Ok.", "text/plain")
            return
        if parsed.path == "/api/v2/torrents/delete":
            f = self._form()
            hashes = (f.get("hashes") or "").lower().split("|")
            delete_files = f.get("deleteFiles", "false") == "true"
            with jobs_lock:
                for h in hashes:
                    j = jobs.pop(h, None)
                    if not j:
                        continue
                    if j.get("uuid"):
                        dz.cancel(j["uuid"])
                    if delete_files:
                        p = os.path.join(j.get("save_path", ""),
                                         j.get("name", ""))
                        if p and os.path.isdir(p):
                            shutil.rmtree(p, ignore_errors=True)
            save_state()
            self._send(200, "Ok.", "text/plain")
            return
        if parsed.path in ("/api/v2/torrents/pause",
                           "/api/v2/torrents/resume"):
            f = self._form()
            hashes = (f.get("hashes") or "all").lower()
            want_pause = parsed.path.endswith("/pause")
            with jobs_lock:
                for h, j in jobs.items():
                    if hashes in ("all", "") or h in hashes.split("|"):
                        j["paused"] = want_pause
            save_state()
            self._send(200, "Ok.", "text/plain")
            return
        self._send(404, "not found", "text/plain")

    def _submit(self, h):
        with jobs_lock:
            j = jobs[h]
            if j.get("uuid") or j.get("status") not in ("queued",):
                return
            did = j["deemix_id"]
        uuid, artist, album, err = dz.add_album(did)
        with jobs_lock:
            if uuid:
                j["uuid"] = uuid
                j["status"] = "downloading"
                j["artist"] = artist or j["artist"]
                j["album"] = album or j["album"]
                per = 35 * 1024 * 1024 if dz.flac else 10 * 1024 * 1024
                try:
                    q = dz.queue().get("queue") or {}
                    item = q.get(uuid) or {}
                    n = int(item.get("size") or 0)
                    if n > 0:
                        j["size"] = n * per
                except Exception:
                    pass
            else:
                j["status"] = "error"
                log(f"submit {h} failed: {err}")
        save_state()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=6596)
    ap.add_argument("--deemix-url", default="http://127.0.0.1:6595")
    ap.add_argument("--music-dir", default="/data/Media/Music")
    ap.add_argument("--staging-dir", default="/data/.deemix-arr-staging")
    ap.add_argument("--state-dir", default="/var/lib/deemix-arr")
    ap.add_argument("--api-key", default="deemix-arr")
    ap.add_argument("--qb-user", default="admin")
    ap.add_argument("--qb-pass", default="adminadmin")
    a = ap.parse_args()
    cfg.update(port=a.port, deemix_url=a.deemix_url, music_dir=a.music_dir,
               staging_dir=a.staging_dir, state_dir=a.state_dir,
               api_key=a.api_key, qb_user=a.qb_user, qb_pass=a.qb_pass)
    global dz
    dz = Deemix(cfg["deemix_url"])
    dz.load_caps()
    log(f"deemix bitrate={dz.bitrate} flac={dz.flac}")
    os.makedirs(cfg["state_dir"], exist_ok=True)
    os.makedirs(cfg["staging_dir"], mode=0o775, exist_ok=True)
    load_state()
    threading.Thread(target=poller, daemon=True).start()
    srv = ThreadingHTTPServer(("127.0.0.1", cfg["port"]), Handler)
    log(f"listening on 127.0.0.1:{cfg['port']}")
    srv.serve_forever()


if __name__ == "__main__":
    main()
