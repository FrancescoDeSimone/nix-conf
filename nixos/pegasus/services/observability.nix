{
  lib,
  pkgs,
  config,
  ...
}: {
  imports = [./grafana-dashboards.nix];
  services = {
    prometheus = {
      enable = true;
      extraFlags = ["--storage.tsdb.retention.size=2GB"];

      exporters = {
        node = {
          enable = true;
          port = config.my.services.node-exporter.port;
          enabledCollectors = ["systemd"];
          disabledCollectors = ["interrupts" "mdadm" "ntp" "qdisc" "runit" "supervisord" "textfile"];
        };
      };

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [{targets = ["localhost:${toString config.my.services.node-exporter.port}"];}];
        }
        {
          job_name = "nginx";
          static_configs = [{targets = ["localhost:${toString config.my.services.nginx.exporter}"];}];
        }
        {
          job_name = "adguard";
          static_configs = [{targets = ["localhost:${toString config.my.services.adguard.exporter}"];}];
        }
        {
          job_name = "sonarr";
          static_configs = [{targets = ["localhost:${toString config.my.services.sonarr.exporter}"];}];
        }
        {
          job_name = "radarr";
          static_configs = [{targets = ["localhost:${toString config.my.services.radarr.exporter}"];}];
        }
        {
          job_name = "prowlarr";
          static_configs = [{targets = ["localhost:${toString config.my.services.prowlarr.exporter}"];}];
        }
        {
          job_name = "qbittorrent";
          static_configs = [{targets = ["localhost:${toString config.my.services.qbittorrent.exporter}"];}];
        }
      ];
    };

    grafana = {
      enable = true;
      settings.server = {
        http_addr = "0.0.0.0";
        http_port = config.my.services.grafana.port;
        domain = "grafana.pegasus.lan";
      };
      provision = {
        enable = true;
        datasources.settings = {
          apiVersion = 1;
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://localhost:${toString config.my.services.prometheus.port}";
              isDefault = true;
              uid = "prometheus_default";
            }
            {
              name = "Loki";
              type = "loki";
              url = "http://localhost:${toString config.my.services.loki.port}";
              uid = "loki_default";
            }
          ];
        };
      };
    };

    loki = {
      enable = true;
      configuration = {
        server.http_listen_port = config.my.services.loki.port;
        auth_enabled = false;
        limits_config = {
          retention_period = "168h";
        };

        compactor = {
          working_directory = "/tmp/loki/compactor";
          compaction_interval = "10m";
          retention_enabled = true;
          retention_delete_delay = "2h";
          retention_delete_worker_count = 150;
          delete_request_store = "filesystem";
        };

        common = {
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "inmemory";
          };
          replication_factor = 1;
          path_prefix = "/tmp/loki";
        };

        schema_config = {
          configs = [
            {
              from = "2020-10-24";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config.filesystem.directory = "/tmp/loki/chunks";
      };
    };

    promtail = {
      enable = true;
      configuration = {
        server.http_listen_port = config.my.services.promtail.port;
        clients = [{url = "http://localhost:${toString config.my.services.loki.port}/loki/api/v1/push";}];
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = "pegasus";
              };
            };
            relabel_configs = [
              {
                source_labels = ["__journal__systemd_unit"];
                target_label = "unit";
              }
            ];
          }
        ];
      };
    };
  };
}
