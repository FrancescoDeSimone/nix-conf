{
  pkgs,
  lib,
  config,
  ...
}: let
  common = {
    datasource = {
      type = "prometheus";
      uid = "prometheus_default";
    };
  };

  systemDashboard = {
    uid = "system-overview";
    title = "Pegasus System";
    tags = ["system"];
    timezone = "browser";
    schemaVersion = 36;
    panels = [
      {
        title = "CPU Usage (5m)";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 12;
          x = 0;
          y = 0;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode='idle'}[5m])) * 100)";
            legendFormat = "{{instance}}";
          }
        ];
      }
      {
        title = "Memory Usage";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 12;
          x = 12;
          y = 0;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = "100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100)";
            legendFormat = "Used %";
          }
        ];
      }
      {
        title = "Disk Usage (Root)";
        type = "gauge";
        gridPos = {
          h = 8;
          w = 8;
          x = 0;
          y = 8;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = "100 - ((node_filesystem_avail_bytes{mountpoint='/'} / node_filesystem_size_bytes{mountpoint='/'}) * 100)";
          }
        ];
      }
      {
        title = "System Load";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 16;
          x = 8;
          y = 8;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = "node_load1";
            legendFormat = "Load 1m";
          }
        ];
      }
    ];
  };

  networkDashboard = {
    uid = "network-security";
    title = "Network & Security";
    tags = ["network" "adguard" "nginx"];
    schemaVersion = 36;
    panels = [
      {
        title = "DNS Queries (AdGuard)";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 12;
          x = 0;
          y = 0;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = "rate(adguard_queries_total[5m])";
            legendFormat = "Queries/s";
          }
        ];
      }
      {
        title = "Blocked Queries";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 12;
          x = 12;
          y = 0;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = "rate(adguard_blocked_queries_total[5m])";
            legendFormat = "Blocked/s";
          }
        ];
      }
      {
        title = "Nginx Active Connections";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 24;
          x = 0;
          y = 8;
        };
        datasource = common.datasource;
        targets = [{expr = "nginx_connections_active";}];
      }
    ];
  };

  mediaDashboard = {
    uid = "media-downloads";
    title = "Media & Downloads";
    tags = ["media" "torrent"];
    schemaVersion = 36;
    panels = [
      {
        title = "qBittorrent Speeds";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 12;
          x = 0;
          y = 0;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = "qbittorrent_download_speed_bytes";
            legendFormat = "Down";
          }
          {
            expr = "qbittorrent_upload_speed_bytes";
            legendFormat = "Up";
          }
        ];
      }
      {
        title = "Media Counts";
        type = "stat";
        gridPos = {
          h = 8;
          w = 12;
          x = 12;
          y = 0;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = "sonarr_series_total";
            legendFormat = "Sonarr Series";
          }
          {
            expr = "radarr_movies_total";
            legendFormat = "Radarr Movies";
          }
        ];
      }
    ];
  };
in {
  services.grafana.provision = {
    enable = true;
    dashboards.settings.providers = [
      {
        name = "Pegasus Dashboards";
        options.path = pkgs.runCommand "grafana-dashboards" {} ''
          mkdir -p $out
          cp ${pkgs.writeText "system.json" (builtins.toJSON systemDashboard)} $out/system.json
          cp ${pkgs.writeText "network.json" (builtins.toJSON networkDashboard)} $out/network.json
          cp ${pkgs.writeText "media.json" (builtins.toJSON mediaDashboard)} $out/media.json
        '';
      }
    ];
  };
}
