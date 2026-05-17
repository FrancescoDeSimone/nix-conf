#!/usr/bin/env python3
import argparse, logging, os, threading, time
from datetime import datetime
from typing import Any, Dict, List, Optional

import requests
from prometheus_client import start_http_server
from prometheus_client.core import GaugeMetricFamily, InfoMetricFamily, REGISTRY

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger('scrutiny_exporter')


class DeviceDetailsCache:
    def __init__(self, cache_duration: int = 60):
        self.cache_duration = cache_duration
        self.cache = {}
        self.lock = threading.Lock()

    def get(self, wwn: str) -> Optional[Dict[str, Any]]:
        with self.lock:
            if wwn in self.cache:
                data, timestamp = self.cache[wwn]
                if time.time() - timestamp < self.cache_duration:
                    return data
                del self.cache[wwn]
            return None

    def set(self, wwn: str, data: Dict[str, Any]):
        with self.lock:
            self.cache[wwn] = (data, time.time())


class ScrutinyCollector:
    def __init__(self, api_url: str, timeout: int = 10, cache_duration: int = 60):
        self.api_url = api_url
        self.timeout = timeout
        self.cache = DeviceDetailsCache(cache_duration)

    def collect(self):
        try:
            r = requests.get(f"{self.api_url}/api/summary", timeout=self.timeout)
            r.raise_for_status()
            data = r.json()
            if 'data' not in data or 'summary' not in data['data']:
                return
            summary = data['data']['summary']
            details = {}
            for wwn in summary.keys():
                d = self._get_device_details(wwn)
                if d:
                    details[wwn] = d
            yield from self._create_device_info_metrics(summary)
            yield from self._create_smart_attributes_metrics(details)
            yield from self._create_summary_metrics(details)
            yield from self._create_status_metrics(summary)
        except Exception as e:
            logger.error(f"Collect failed: {e}")

    def _get_device_details(self, wwn: str) -> Dict:
        cached = self.cache.get(wwn)
        if cached:
            return cached
        try:
            r = requests.get(f"{self.api_url}/api/device/{wwn}/details", timeout=self.timeout)
            r.raise_for_status()
            data = r.json()
            self.cache.set(wwn, data)
            return data
        except Exception as e:
            logger.warning(f"Failed to get {wwn}: {e}")
            return {}

    def _create_device_info_metrics(self, summary: Dict):
        info = GaugeMetricFamily('scrutiny_device_info', 'Device info',
                                 labels=['wwn', 'device_name', 'model_name', 'serial_number',
                                         'firmware', 'protocol', 'host_id', 'form_factor'])
        cap = GaugeMetricFamily('scrutiny_device_capacity_bytes', 'Device capacity',
                                labels=['wwn', 'device_name', 'model_name', 'protocol', 'host_id'])
        status = GaugeMetricFamily('scrutiny_device_status', 'Device status (0=pass, 1=fail)',
                                   labels=['wwn', 'device_name', 'model_name', 'protocol', 'host_id'])
        for wwn, d in summary.items():
            dev = d.get('device', {})
            dn = dev.get('device_name', '')
            mn = dev.get('model_name', '')
            pt = dev.get('device_protocol', '')
            hi = dev.get('host_id', '')
            info.add_metric([wwn, dn, mn, dev.get('serial_number', ''), dev.get('firmware', ''), pt, hi, dev.get('form_factor', '')], 1)
            cl = [wwn, dn, mn, pt, hi]
            if dev.get('capacity'):
                cap.add_metric(cl, dev['capacity'])
            status.add_metric(cl, dev.get('device_status', 0))
        yield info; yield cap; yield status

    def _create_smart_attributes_metrics(self, details: Dict):
        gauges = {}; infos = {}
        for wwn, dd in details.items():
            if 'data' not in dd: continue
            dev = dd['data'].get('device', {})
            results = dd['data'].get('smart_results', [])
            if not results: continue
            latest = self._select_latest_result(results)
            if not latest: continue
            attrs = latest.get('attrs', {})
            dn = dev.get('device_name', ''); mn = dev.get('model_name', '')
            pt = dev.get('device_protocol', ''); hi = dev.get('host_id', '')
            for aid, ad in attrs.items():
                if not isinstance(ad, dict): continue
                sid = str(aid).strip().replace(' ', '_').replace('-', '_').replace('.', '_').lower()
                labels = [wwn, dn, mn, pt, hi, str(aid)]
                for pn, pv in ad.items():
                    if pv is None: continue
                    sp = pn.strip().replace(' ', '_').replace('-', '_').replace('.', '_').lower()
                    mb = f"scrutiny_smart_attr_{sid}_{sp}"
                    nv = self._try_parse_float(pv)
                    if nv is not None:
                        if mb not in gauges:
                            gauges[mb] = GaugeMetricFamily(mb, f"SMART {aid} {pn}",
                                                           labels=['wwn','device_name','model_name','protocol','host_id','attribute_id'])
                        gauges[mb].add_metric(labels, nv)
                    else:
                        im = f"{mb}_info"
                        if im not in infos:
                            infos[im] = InfoMetricFamily(im, f"SMART {aid} {pn} (str)",
                                                         labels=['wwn','device_name','model_name','protocol','host_id','attribute_id'])
                        infos[im].add_metric(labels, {'value': str(pv)})
        yield from gauges.values()
        yield from infos.values()

    def _create_summary_metrics(self, details: Dict):
        temp = GaugeMetricFamily('scrutiny_smart_temperature_celsius', 'Temperature',
                                 labels=['wwn','device_name','model_name','protocol','host_id'])
        poh = GaugeMetricFamily('scrutiny_smart_power_on_hours', 'Power-on hours',
                                labels=['wwn','device_name','model_name','protocol','host_id'])
        pcc = GaugeMetricFamily('scrutiny_smart_power_cycle_count', 'Power cycle count',
                                labels=['wwn','device_name','model_name','protocol','host_id'])
        ts = GaugeMetricFamily('scrutiny_smart_collector_timestamp', 'Collection timestamp',
                               labels=['wwn','device_name','model_name','protocol','host_id'])
        for wwn, dd in details.items():
            if 'data' not in dd: continue
            dev = dd['data'].get('device', {}); results = dd['data'].get('smart_results', [])
            if not results: continue
            latest = self._select_latest_result(results)
            if not latest: continue
            labels = [wwn, dev.get('device_name',''), dev.get('model_name',''), dev.get('device_protocol',''), dev.get('host_id','')]
            if latest.get('temp') is not None: temp.add_metric(labels, float(latest['temp']))
            if latest.get('power_on_hours') is not None: poh.add_metric(labels, float(latest['power_on_hours']))
            if latest.get('power_cycle_count') is not None: pcc.add_metric(labels, float(latest['power_cycle_count']))
            if latest.get('date'):
                try:
                    t = datetime.fromisoformat(str(latest['date']).replace('Z','+00:00')).timestamp() * 1000
                    ts.add_metric(labels, t)
                except: pass
        yield temp; yield poh; yield pcc; yield ts

    def _create_status_metrics(self, summary: Dict):
        total = GaugeMetricFamily('scrutiny_devices_total', 'Total devices', labels=[])
        total.add_metric([], len(summary))
        yield total
        proto = GaugeMetricFamily('scrutiny_devices_by_protocol', 'Devices by protocol', labels=['protocol'])
        counts = {}
        for d in summary.values():
            p = d.get('device', {}).get('device_protocol', 'unknown')
            counts[p] = counts.get(p, 0) + 1
        for p, c in counts.items(): proto.add_metric([p], c)
        yield proto

    @staticmethod
    def _try_parse_float(v: Any) -> Optional[float]:
        if isinstance(v, (int, float)): return float(v)
        if isinstance(v, str):
            v = v.strip()
            if not v: return None
            try: return float(v)
            except:
                try: return float(int(v, 16))
                except: return None
        return None

    def _select_latest_result(self, results: List) -> Optional[Dict]:
        latest, lts = None, None
        for r in results:
            ts = self._parse_ts(r)
            if latest is None or (ts is not None and (lts is None or ts > lts)):
                latest, lts = r, ts
        return latest or (results[-1] if results else None)

    @staticmethod
    def _parse_ts(r: Dict) -> Optional[float]:
        for k in ('date','smart_date','collector_date'):
            v = r.get(k)
            if v:
                try: return datetime.fromisoformat(str(v).replace('Z','+00:00')).timestamp()
                except: pass
        return None


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--api-url', default=os.environ.get('SCRUTINY_API_URL', 'http://localhost:8080'))
    p.add_argument('--port', type=int, default=int(os.environ.get('EXPORTER_PORT','9900')))
    p.add_argument('--timeout', type=int, default=int(os.environ.get('API_TIMEOUT','10')))
    p.add_argument('--cache-duration', type=int, default=int(os.environ.get('CACHE_DURATION','60')))
    p.add_argument('--log-level', choices=['DEBUG','INFO','WARNING','ERROR'],
                   default=os.environ.get('LOG_LEVEL','INFO').upper())
    args = p.parse_args()
    logging.getLogger().setLevel(getattr(logging, args.log_level))
    REGISTRY.register(ScrutinyCollector(args.api_url, args.timeout, args.cache_duration))
    logger.info(f"Starting scrutiny-exporter on :{args.port}, API: {args.api_url}")
    start_http_server(args.port)
    try:
        while True: time.sleep(1)
    except KeyboardInterrupt: pass

if __name__ == '__main__':
    main()
