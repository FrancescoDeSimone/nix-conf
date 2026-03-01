{ config
, pkgs
, ...
}: {
  services.prometheus.exporters.exportarr = {
    sonarr = {
      enable = true;
      port = config.my.services.sonarr.exporter;
      url = "http://127.0.0.1:${toString config.my.services.sonarr.port}";
    };
    radarr = {
      enable = true;
      port = config.my.services.radarr.exporter;
      url = "http://127.0.0.1:${toString config.my.services.radarr.port}";
    };
    prowlarr = {
      enable = true;
      port = config.my.services.prowlarr.exporter;
      url = "http://127.0.0.1:${toString config.my.services.prowlarr.port}";
    };
  };

  services.prometheus.exporters.qbittorrent = {
    enable = true;
    port = config.my.services.qbittorrent.exporter;
    url = "http://127.0.0.1:${toString config.my.services.qbittorrent.port}";
  };
}
