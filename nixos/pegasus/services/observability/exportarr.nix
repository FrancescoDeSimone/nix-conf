{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkExporter =
    {
      exporterPort,
      servicePort,
      configPath ? null,
      apiKeyFile ? null,
      user ? "root",
      environment ? { },
    }:
    {
      enable = true;
      package = pkgs.exportarr;
      listenAddress = "127.0.0.1";
      port = exporterPort;
      url = "http://127.0.0.1:${toString servicePort}";
      inherit user;
      environment = environment // lib.optionalAttrs (configPath != null) { CONFIG = configPath; };
    }
    // lib.optionalAttrs (apiKeyFile != null) { inherit apiKeyFile; };
in
{
  services.prometheus.exporters = lib.mkMerge [
    (lib.optionalAttrs config.services.sonarr.enable {
      exportarr-sonarr = mkExporter {
        exporterPort = config.my.services.sonarr.exporter;
        servicePort = config.my.services.sonarr.port;
        configPath = "${config.services.sonarr.dataDir}/config.xml";
        user = config.services.sonarr.user;
      };
    })
    (lib.optionalAttrs config.services.radarr.enable {
      exportarr-radarr = mkExporter {
        exporterPort = config.my.services.radarr.exporter;
        servicePort = config.my.services.radarr.port;
        configPath = "${config.services.radarr.dataDir}/config.xml";
        user = config.services.radarr.user;
      };
    })
    (lib.optionalAttrs config.services.lidarr.enable {
      exportarr-lidarr = mkExporter {
        exporterPort = config.my.services.lidarr.exporter;
        servicePort = config.my.services.lidarr.port;
        configPath = "${config.services.lidarr.dataDir}/config.xml";
        user = config.services.lidarr.user;
      };
    })
    (lib.optionalAttrs config.services.prowlarr.enable {
      exportarr-prowlarr = mkExporter {
        exporterPort = config.my.services.prowlarr.exporter;
        servicePort = config.my.services.prowlarr.port;
        configPath = "${config.services.prowlarr.dataDir}/config.xml";
        user = "root";
      };
    })
    (lib.optionalAttrs config.services.readarr.enable {
      exportarr-readarr = mkExporter {
        exporterPort = config.my.services.readarr.exporter;
        servicePort = config.my.services.readarr.port;
        configPath = "${config.services.readarr.dataDir}/config.xml";
        user = config.services.readarr.user;
      };
    })
    (lib.optionalAttrs (config.services.bazarr.enable && config.age.secrets ? bazarr) {
      exportarr-bazarr = mkExporter {
        exporterPort = config.my.services.bazarr.exporter;
        servicePort = config.my.services.bazarr.port;
        apiKeyFile = config.age.secrets.bazarr.path;
        user = "root";
      };
    })
  ];
}
