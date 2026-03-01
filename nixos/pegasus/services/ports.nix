{ lib, ... }:
let
  inherit (lib) mkOption types;

  mkService = defaultPort: {
    port = mkOption {
      type = types.port;
      default = defaultPort;
    };
  };

  mkServiceWithExporter = defaultPort: exporterPort: {
    port = mkOption {
      type = types.port;
      default = defaultPort;
    };
    exporter = mkOption {
      type = types.port;
      default = exporterPort;
    };
  };
in
{
  options.my.services = {
    # Proxies & Web
    nginx = mkServiceWithExporter 80 9113;
    homepage = mkService 8888;

    # Security & DNS
    adguard = mkServiceWithExporter 3003 9617;

    # Monitoring & Observability
    glances = mkService 61208;
    grafana = mkService 3030;
    prometheus = mkService 9090;
    loki = mkService 3100;
    promtail = mkService 9080;
    node-exporter = mkService 9002;
    process-exporter = mkService 9005;
    systemd-exporter = mkService 9006;
    ntopng = mkService 7777;
    speedtesttracker = mkService 8765;

    # Media & Arr Stack
    jellyfin = mkService 8096;
    jellyseerr = mkService 5055;
    sonarr = mkServiceWithExporter 8989 9898;
    radarr = mkServiceWithExporter 7878 9707;
    lidarr = mkService 8686;
    prowlarr = mkServiceWithExporter 9696 9697;

    # Downloading
    transmission = mkService 9091;
    qui = mkService 8091;
    qbittorrent = mkServiceWithExporter 8090 9999;
    slskd = mkService 5030;
    flaresolverr = mkService 8191;

    # Tools & Productivity
    stirling-pdf = mkService 8085;
    filebrowser = mkService 8082;
    it-tools = mkService 80;
    scrutiny = mkService 8081;
    nextcloud = mkService 8010;
    hoarder = mkService 3002;
    govd = mkService 8083;
    opencloud = mkService 8080;
    git = mkService 3001;
    ollama = mkService 11434;
    jelly-clipper = mkService 3333;
    bypass = mkService 5000;
  };
}
