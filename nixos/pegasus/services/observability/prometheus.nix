{
  config,
  lib,
  pkgs,
  private,
  ...
}: let
  domain = private.nginx.domain;
  headscaleTailnetMetricsDir = "/var/lib/prometheus-node-exporter-textfile";
  blackboxTargets = [
    {
      name = "homepage";
      url = "http://127.0.0.1:${toString config.my.services.homepage.port}";
    }
    {
      name = "grafana";
      url = "http://127.0.0.1:${toString config.my.services.grafana.port}";
    }
    {
      name = "jellyfin";
      url = "http://127.0.0.1:${toString config.my.services.jellyfin.port}";
    }
    {
      name = "jellyseerr";
      url = "http://127.0.0.1:${toString config.my.services.jellyseerr.port}";
    }
    {
      name = "sonarr";
      url = "http://127.0.0.1:${toString config.my.services.sonarr.port}";
    }
    {
      name = "radarr";
      url = "http://127.0.0.1:${toString config.my.services.radarr.port}";
    }
    {
      name = "lidarr";
      url = "http://127.0.0.1:${toString config.my.services.lidarr.port}";
    }
    {
      name = "prowlarr";
      url = "http://127.0.0.1:${toString config.my.services.prowlarr.port}";
    }
    {
      name = "qbittorrent";
      url = "http://127.0.0.1:${toString config.my.services.qui.port}";
    }
    {
      name = "stirling-pdf";
      url = "http://127.0.0.1:${toString config.my.services.stirling-pdf.port}";
    }
    {
      name = "filebrowser";
      url = "http://127.0.0.1:${toString config.my.services.filebrowser.port}";
    }
    {
      name = "scrutiny";
      url = "http://127.0.0.1:${toString config.my.services.scrutiny.port}";
    }
    {
      name = "karakeep";
      url = "http://127.0.0.1:${toString config.my.services.karakeep.port}";
    }
    {
      name = "bypass";
      url = "http://127.0.0.1:${toString config.my.services.bypass.port}";
    }
    {
      name = "speedtest-tracker";
      url = "http://127.0.0.1:${toString config.my.services.speedtest-tracker.port}";
    }
    {
      name = "adguard";
      url = "http://127.0.0.1:${toString config.my.services.adguard.port}";
    }
    {
      name = "headscale";
      url = "http://127.0.0.1:${toString config.my.services.headscale.port}";
    }
    {
      name = "nextcloud";
      url = "https://nextcloud.${domain}";
      module = "https_2xx";
    }
    {
      name = "git";
      url = "http://192.168.200.11:${toString config.my.services.git.port}";
    }
    # {
    #   name = "opencloud";
    #   url = "http://192.168.103.11:${toString config.my.services.opencloud.port}";
    # }
  ];
  mkStaticScrape = name: port: {
    job_name = name;
    static_configs = [{targets = ["127.0.0.1:${toString port}"];}];
  };
in {
  services.prometheus = {
    enable = true;
    extraFlags = ["--storage.tsdb.retention.size=2GB"];

    exporters = {
      node = {
        enable = true;
        port = config.my.services.node-exporter.port;
        enabledCollectors = [
          "systemd"
          "textfile"
        ];
        disabledCollectors = [
          "interrupts"
          "mdadm"
          "ntp"
          "qdisc"
          "runit"
          "supervisord"
        ];
        extraFlags = ["--collector.textfile.directory=${headscaleTailnetMetricsDir}"];
      };

      blackbox = {
        enable = true;
        port = config.my.services.blackbox-exporter.port;
        listenAddress = "127.0.0.1";
        configFile = pkgs.writeText "blackbox.yml" (
          builtins.toJSON {
            modules = {
              http_2xx = {
                prober = "http";
                timeout = "10s";
                http = {
                  valid_http_versions = [
                    "HTTP/1.1"
                    "HTTP/2.0"
                  ];
                  valid_status_codes = [
                    200
                    301
                    302
                    303
                    307
                    308
                    401
                    403
                    404
                  ];
                  method = "GET";
                  follow_redirects = true;
                  preferred_ip_protocol = "ip4";
                };
              };
              https_2xx = {
                prober = "http";
                timeout = "10s";
                http = {
                  valid_http_versions = [
                    "HTTP/1.1"
                    "HTTP/2.0"
                  ];
                  valid_status_codes = [
                    200
                    301
                    302
                    303
                    307
                    308
                    401
                    403
                    404
                  ];
                  method = "GET";
                  follow_redirects = true;
                  preferred_ip_protocol = "ip4";
                  tls_config.insecure_skip_verify = true;
                };
              };
            };
          }
        );
      };
    };

    scrapeConfigs =
      [
        (mkStaticScrape "node" config.my.services.node-exporter.port)
        (mkStaticScrape "nginx" config.my.services.nginx.exporter)
      ]
      ++ lib.optionals config.services.prometheus.exporters.exportarr-sonarr.enable [
        (mkStaticScrape "sonarr" config.services.prometheus.exporters.exportarr-sonarr.port)
      ]
      ++ lib.optionals config.services.prometheus.exporters.exportarr-radarr.enable [
        (mkStaticScrape "radarr" config.services.prometheus.exporters.exportarr-radarr.port)
      ]
      ++ lib.optionals config.services.prometheus.exporters.exportarr-lidarr.enable [
        (mkStaticScrape "lidarr" config.services.prometheus.exporters.exportarr-lidarr.port)
      ]
      ++ lib.optionals config.services.prometheus.exporters.exportarr-prowlarr.enable [
        (mkStaticScrape "prowlarr" config.services.prometheus.exporters.exportarr-prowlarr.port)
      ]
      ++ lib.optionals config.services.prometheus.exporters.exportarr-readarr.enable [
        (mkStaticScrape "readarr" config.services.prometheus.exporters.exportarr-readarr.port)
      ]
      ++ lib.optionals config.services.prometheus.exporters.exportarr-bazarr.enable [
        (mkStaticScrape "bazarr" config.services.prometheus.exporters.exportarr-bazarr.port)
      ]
      ++ [
        {
          job_name = "blackbox";
          metrics_path = "/probe";
          params.module = ["http_2xx"];
          static_configs =
            map (t: {
              targets = [t.url];
              labels = {
                service = t.name;
                __param_module = t.module or "http_2xx";
              };
            })
            blackboxTargets;
          relabel_configs = [
            {
              source_labels = ["__param_module"];
              target_label = "__param_module";
            }
            {
              source_labels = ["__address__"];
              target_label = "__param_target";
            }
            {
              source_labels = ["service"];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "127.0.0.1:${toString config.my.services.blackbox-exporter.port}";
            }
          ];
        }
        (mkStaticScrape "blackbox_exporter" config.my.services.blackbox-exporter.port)
        {
          job_name = "speedtest-tracker";
          metrics_path = "/prometheus";
          scrape_interval = "5m";
          static_configs = [
            {targets = ["127.0.0.1:${toString config.my.services.speedtest-tracker.port}"];}
          ];
        }
        {
          job_name = "adguard-exporter";
          static_configs = [{targets = ["localhost:9618"];}];
        }
        {
          job_name = "tailscale-exporter";
          static_configs = [{targets = ["localhost:${toString config.my.services.tailscale-exporter.port}"];}];
          scrape_interval = "30s";
          metrics_path = "/metrics";
        }
      ];
  };
}
