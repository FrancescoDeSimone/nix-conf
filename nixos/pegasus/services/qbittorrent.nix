{
  lib,
  private,
  config,
  pkgs,
  ...
}: let
  qbuser = private.qb.user;
  qbpasswd = private.qb.passwd;
  telegramNotifyScript = pkgs.writeShellScript "qbittorrent-telegram-notify" ''
        set -eu

        secret_file=${config.age.secrets."telegram-qbittorrent".path}
        torrent_name="''${1:-unknown}"
        content_path="''${2:-unknown}"
        category="''${3:-}"
        torrent_id="''${4:-}"

        if [ ! -r "$secret_file" ]; then
          printf '%s\n' "qBittorrent Telegram secret is not readable: $secret_file" >&2
          exit 1
        fi

        . "$secret_file"
        : "''${BOT_TOKEN:?Missing BOT_TOKEN in $secret_file}"
        : "''${CHAT_ID:?Missing CHAT_ID in $secret_file}"

        message="qBittorrent download finished on ${config.networking.hostName}
    Name: $torrent_name
    Path: $content_path"

        if [ -n "$category" ]; then
          message="$message
    Category: $category"
        fi

        if [ -n "$torrent_id" ] && [ "$torrent_id" != "-" ]; then
          message="$message
    Torrent ID: $torrent_id"
        fi

        ${pkgs.curl}/bin/curl \
          --silent \
          --show-error \
          --fail \
          --max-time 10 \
          --retry 3 \
          --data-urlencode "chat_id=$CHAT_ID" \
          --data-urlencode "text=$message" \
          "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
          > /dev/null
  '';

  qbOnFinishedScript = pkgs.writeShellScript "qbittorrent-on-finished" ''
    set -eu
    export PATH=${lib.makeBinPath [ pkgs.curl pkgs.jq pkgs.coreutils pkgs.gnugrep pkgs.gnused ]}:$PATH

    torrent_name="''${1:-unknown}"
    content_path="''${2:-unknown}"
    category="''${3:-}"
    infohash="''${4:-}"
    torrent_id="''${5:-}"

    QBIT_URL="http://127.0.0.1:${toString config.my.services.qbittorrent.port}"
    SONARR_URL="http://127.0.0.1:${toString config.my.services.sonarr.port}"
    SONARR_CONFIG="${config.services.sonarr.dataDir}/config.xml"
    QBIT_SECRET_FILE=${config.age.secrets."qbittorrent-api".path}
    QBIT_DEFAULT_USER=${lib.escapeShellArg qbuser}
    NOTIFY=${telegramNotifyScript}

    log() { printf '%s\n' "qbittorrent-on-finished: $*" >&2; }

    lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

    is_exe_path() {
      case "$(lower "$1")" in
        *.exe) return 0 ;;
        *) return 1 ;;
      esac
    }

    QBIT_USER="$QBIT_DEFAULT_USER"
    QBIT_BEARER=""
    QBIT_PASS=""
    if [ -r "$QBIT_SECRET_FILE" ]; then
      . "$QBIT_SECRET_FILE" || log "warning: could not source $QBIT_SECRET_FILE"
      if [ -n "''${QBITTORRENT_API_KEY:-}" ] && [ "$QBITTORRENT_API_KEY" != "PLACEHOLDER" ]; then
        case "$QBITTORRENT_API_KEY" in
          qbt_*) QBIT_BEARER="$QBITTORRENT_API_KEY" ;;
          *) QBIT_PASS="$QBITTORRENT_API_KEY" ;;
        esac
      fi
      if [ -n "''${QB_PASSWORD:-}" ] && [ "$QB_PASSWORD" != "PLACEHOLDER" ]; then
        QBIT_PASS="$QB_PASSWORD"
      fi
      if [ -n "''${QB_USERNAME:-}" ]; then
        QBIT_USER="$QB_USERNAME"
      fi
    fi

    COOKIE_JAR=""
    HAVE_QBIT_AUTH="unknown"
    qbit_login() {
      COOKIE_JAR="$(mktemp /tmp/qbittorrent-cookies.XXXXXX)"
      code="$(curl --silent --show-error --max-time 10 \
        --header "Referer: $QBIT_URL" \
        --cookie-jar "$COOKIE_JAR" \
        --output /dev/null --write-out '%{http_code}' \
        --data-urlencode "username=$QBIT_USER" \
        --data-urlencode "password=$QBIT_PASS" \
        "$QBIT_URL/api/v2/auth/login" || true)"
      case "$code" in
        200|204) return 0 ;;
        *)
          rm -f "$COOKIE_JAR"
          COOKIE_JAR=""
          return 1
          ;;
      esac
    }
    ensure_qbit_auth() {
      if [ "$HAVE_QBIT_AUTH" = "yes" ]; then return 0; fi
      if [ "$HAVE_QBIT_AUTH" = "no" ]; then return 1; fi
      if [ -n "$QBIT_BEARER" ]; then
        HAVE_QBIT_AUTH="yes"
        return 0
      fi
      if [ -n "$QBIT_PASS" ]; then
        if qbit_login; then
          HAVE_QBIT_AUTH="yes"
          return 0
        fi
        log "warning: qBittorrent login failed, skipping qBittorrent API steps"
      else
        log "warning: no qBittorrent API credential in $QBIT_SECRET_FILE, skipping qBittorrent API steps"
      fi
      HAVE_QBIT_AUTH="no"
      return 1
    }
    qbit_curl() {
      if [ -n "$QBIT_BEARER" ]; then
        curl --silent --show-error \
          --header "Referer: $QBIT_URL" \
          --header "Authorization: Bearer $QBIT_BEARER" \
          "$@"
      else
        curl --silent --show-error \
          --header "Referer: $QBIT_URL" \
          --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
          "$@"
      fi
    }

    # Resolve a usable info hash: prefer %I, fall back to %K.
    # Rejects qBittorrent placeholders passed through literally ("%I"/"%K"/"-").
    HASH=""
    for cand in "$infohash" "$torrent_id"; do
      case "$cand" in
        ""|"-"|"unknown"|"%I"|"%K") continue ;;
        *)
          if printf '%s' "$cand" | grep -Eq '^[A-Fa-f0-9]{32,64}$'; then
            HASH="$(lower "$cand")"
            break
          fi
          ;;
      esac
    done

    # Fast path: name or content path ends with .exe (case-insensitive).
    junk_by_name=0
    if is_exe_path "$torrent_name" || is_exe_path "$content_path"; then
      junk_by_name=1
    fi

    is_junk="$junk_by_name"

    if [ "$junk_by_name" -eq 0 ] && [ -n "$HASH" ] && ensure_qbit_auth; then
      files_json="$(qbit_curl --max-time 10 \
        "$QBIT_URL/api/v2/torrents/files?hash=$HASH" || true)"
      if [ -n "$files_json" ] \
        && printf '%s' "$files_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
        total="$(printf '%s' "$files_json" | jq -r 'length')"
        has_exe="$(printf '%s' "$files_json" \
          | jq -r '[.[] | select(.name | test("\\.exe$"; "i"))] | length')"
        has_video="$(printf '%s' "$files_json" \
          | jq -r '[.[] | select(.name | test("\\.(mkv|mp4|avi|mov|m4v|ts|m2ts|wmv|flv|webm)$"; "i"))] | length')"
        if [ "$total" -gt 0 ] && [ "$has_video" -eq 0 ] && [ "$has_exe" -gt 0 ]; then
          is_junk=1
        fi
      fi
    fi

    # Not junk: keep previous behaviour (Telegram notification).
    if [ "$is_junk" -eq 0 ]; then
      display_id="$torrent_id"
      if [ -z "$display_id" ] || [ "$display_id" = "-" ]; then display_id="$infohash"; fi
      exec "$NOTIFY" "$torrent_name" "$content_path" "$category" "$display_id"
    fi

    printf '%s\n' "qbittorrent-on-finished: junk .exe detected, cleaning up: $torrent_name (hash=''${HASH:-none})" >&2

    delete_hashes="$HASH"
    if [ -z "$delete_hashes" ] && ensure_qbit_auth; then
      info_json="$(qbit_curl --max-time 10 \
        "$QBIT_URL/api/v2/torrents/info" || true)"
      if [ -n "$info_json" ] \
        && printf '%s' "$info_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
        delete_hashes="$(printf '%s' "$info_json" \
          | jq -r --arg n "$torrent_name" '[.[] | select(.name == $n) | .hash] | join("|")' 2>/dev/null || true)"
      fi
    fi
    if [ -n "$delete_hashes" ] && ensure_qbit_auth; then
      qbit_curl --max-time 15 \
        --data-urlencode "hashes=$delete_hashes" \
        --data-urlencode "deleteFiles=true" \
        "$QBIT_URL/api/v2/torrents/delete" >/dev/null \
        || printf '%s\n' "qbittorrent-on-finished: qBittorrent delete failed for $torrent_name" >&2
    elif [ -z "$delete_hashes" ]; then
      printf '%s\n' "qbittorrent-on-finished: no hash found, skipping qBittorrent delete for $torrent_name" >&2
    fi
    if [ -n "$COOKIE_JAR" ]; then rm -f "$COOKIE_JAR"; fi

    # Belt and braces: remove a leftover .exe file if one exists on disk.
    if is_exe_path "$content_path" && [ -e "$content_path" ]; then
      rm -f -- "$content_path" \
        || printf '%s\n' "qbittorrent-on-finished: could not rm $content_path" >&2
    fi

    if [ -r "$SONARR_CONFIG" ]; then
      apikey="$(sed -n 's:.*<ApiKey>\([^<]*\)</ApiKey>.*:\1:p' "$SONARR_CONFIG" | head -n 1)"
      if [ -n "$apikey" ]; then
        queue_json="$(curl --silent --show-error --max-time 10 \
          --header "X-Api-Key: $apikey" \
          "$SONARR_URL/api/v3/queue?page=1&pageSize=200&includeUnknownSeriesItems=true" || true)"
        if [ -n "$queue_json" ] \
          && printf '%s' "$queue_json" | jq -e '.records | type == "array"' >/dev/null 2>&1; then
          queue_ids="$(printf '%s' "$queue_json" | jq -r \
            --arg h "$HASH" --arg n "$torrent_name" \
            '[.records[] | select(.title == $n or (($h != "") and ((.downloadId // "") != "") and ((.downloadId // "") | test("^" + $h + "$"; "i")))) | .id] | .[]' \
            2>/dev/null || true)"
          for qid in $queue_ids; do
            curl --silent --show-error --max-time 10 --request DELETE \
              --header "X-Api-Key: $apikey" \
              "$SONARR_URL/api/v3/queue/$qid?removeFromClient=true&blocklist=true" >/dev/null \
              || printf '%s\n' "qbittorrent-on-finished: Sonarr queue delete failed for id $qid" >&2
          done
        else
          printf '%s\n' "qbittorrent-on-finished: Sonarr queue fetch failed, skipping blacklist" >&2
        fi
      else
        printf '%s\n' "qbittorrent-on-finished: no Sonarr ApiKey in $SONARR_CONFIG, skipping blacklist" >&2
      fi
    else
      printf '%s\n' "qbittorrent-on-finished: Sonarr config not readable ($SONARR_CONFIG), skipping blacklist" >&2
    fi

    exit 0
  '';
in {
  services.qui = {
    enable = true;
    openFirewall = false;
    package = pkgs.unstable.qui;
    settings = {
      port = config.my.services.qui.port;
      host = "127.0.0.1";
    };
    secretFile = config.age.secrets.qui.path;
  };

  services.qbittorrent = {
    enable = true;
    user = "thinkcentre";
    group = "thinkcentre";
    profileDir = "/data/qbittorrent";
    openFirewall = false;
    webuiPort = config.my.services.qbittorrent.port;

    serverConfig = {
      AutoRun = {
        enabled = true;
        program = ''${qbOnFinishedScript} "%N" "%F" "%L" "%I" "%K"'';
      };

      LegalNotice.Accepted = true;
      Preferences = {
        WebUI = {
          Enabled = true;
          Address = "127.0.0.1";
          Port = config.my.services.qbittorrent.port;
          Username = qbuser;
          Password_PBKDF2 = qbpasswd;
          CSRFProtection = true;
          LocalHostAuth = true;
        };
        General.Locale = "en";
      };

      BitTorrent = {
        ExcludedFileNamesEnabled = true;
        Session = {
          ExcludedFileNames = lib.concatStringsSep ", " [
            "*.lnk"
            "*.zipx"
            "*sample.mkv"
            "*sample.avi"
            "*sample.mp4"
            "*.py"
            "*.vbs"
            "*.html"
            "*.php"
            "*.torrent"
            "*.exe"
            "*.bat"
            "*.cmd"
            "*.com"
            "*.cpl"
            "*.dll"
            "*.js"
            "*.jse"
            "*.msi"
            "*.msp"
            "*.pif"
            "*.scr"
            "*.vbe"
            "*.wsf"
            "*.wsh"
            "*.hta"
            "*.reg"
            "*.inf"
            "*.ps1"
            "*.ps2"
            "*.psm1"
            "*.psd1"
            "*.sh"
            "*.apk"
            "*.app"
            "*.ipa"
            "*.iso"
            "*.jar"
            "*.bin"
            "*.tmp"
            "*.vb"
            "*.vxd"
            "*.ocx"
            "*.drv"
            "*.sys"
            "*.scf"
            "*.ade"
            "*.adp"
            "*.bas"
            "*.chm"
            "*.crt"
            "*.hlp"
            "*.ins"
            "*.isp"
            "*.key"
            "*.mda"
            "*.mdb"
            "*.mdt"
            "*.mdw"
            "*.mdz"
            "*.potm"
            "*.potx"
            "*.ppam"
            "*.ppsx"
            "*.pptm"
            "*.sldm"
            "*.sldx"
            "*.xlam"
            "*.xlsb"
            "*.xlsm"
            "*.xltm"
            "*.nsh"
            "*.mht"
            "*.mhtml"
          ];
          BandwidthSchedulerEnabled = true;
          AlternativeGlobalDLSpeedLimit = 102400;
          AlternativeGlobalUPSpeedLimit = 102400;
          GlobalDLSpeedLimit = 0;
          GlobalUPSpeedLimit = 0;
          QueueingSystemEnabled = false;
          GlobalMaxRatio = -1;
          GlobalMaxSeedingMinutes = -1;
        };
      };

      Preferences.Scheduler = {
        days = 0;
        start_time = "08:00";
        end_time = "22:00";
      };
    };
  };

  users.users.thinkcentre = {
    isNormalUser = true;
    group = "thinkcentre";
  };
  users.groups.thinkcentre = {};
}
