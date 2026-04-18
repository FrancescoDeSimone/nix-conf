{
  config,
  pkgs,
  lib,
  private,
  ...
}: let
  domain = private.nginx.domain;
  # All services to probe via blackbox HTTP checks
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
      name = "speedtesttracker";
      url = "http://127.0.0.1:${toString config.my.services.speedtesttracker.port}";
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
    {
      name = "opencloud";
      url = "http://192.168.103.11:${toString config.my.services.opencloud.port}";
    }
  ];

  # Generate the contact point YAML from the agenix secret at startup
  telegramContactPointScript = pkgs.writeShellScript "grafana-telegram-setup" ''
    if [ -f "${config.age.secrets.telegram.path}" ]; then
      source "${config.age.secrets.telegram.path}"
      mkdir -p /var/lib/grafana/provisioning/alerting
      cat > /var/lib/grafana/provisioning/alerting/telegram.yaml << EOF
    apiVersion: 1
    contactPoints:
      - orgId: 1
        name: telegram
        receivers:
          - uid: telegram-default
            type: telegram
            settings:
              bottoken: $BOT_TOKEN
              chatid: "$CHAT_ID"
              parse_mode: HTML
    policies:
      - orgId: 1
        receiver: telegram
        group_by: ['alertname', 'service']
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 4h
    EOF
    fi
  '';
in {
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

        blackbox = {
          enable = true;
          port = config.my.services.blackbox-exporter.port;
          listenAddress = "127.0.0.1";
          configFile = pkgs.writeText "blackbox.yml" (builtins.toJSON {
            modules = {
              http_2xx = {
                prober = "http";
                timeout = "10s";
                http = {
                  valid_http_versions = ["HTTP/1.1" "HTTP/2.0"];
                  valid_status_codes = [200 301 302 303 307 308 401 403];
                  method = "GET";
                  follow_redirects = true;
                  preferred_ip_protocol = "ip4";
                };
              };
              https_2xx = {
                prober = "http";
                timeout = "10s";
                http = {
                  valid_http_versions = ["HTTP/1.1" "HTTP/2.0"];
                  valid_status_codes = [200 301 302 303 307 308 401 403];
                  method = "GET";
                  follow_redirects = true;
                  preferred_ip_protocol = "ip4";
                  tls_config.insecure_skip_verify = true;
                };
              };
            };
          });
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
        # Exportarr-based scrape configs (disabled: exportarr module not in nixpkgs)
        # {
        #   job_name = "sonarr";
        #   static_configs = [{targets = ["localhost:${toString config.my.services.sonarr.exporter}"];}];
        # }
        # {
        #   job_name = "radarr";
        #   static_configs = [{targets = ["localhost:${toString config.my.services.radarr.exporter}"];}];
        # }
        # {
        #   job_name = "prowlarr";
        #   static_configs = [{targets = ["localhost:${toString config.my.services.prowlarr.exporter}"];}];
        # }
        # {
        #   job_name = "qbittorrent";
        #   static_configs = [{targets = ["localhost:${toString config.my.services.qbittorrent.exporter}"];}];
        # }
        {
          job_name = "blackbox";
          metrics_path = "/probe";
          params.module = ["http_2xx"];
          static_configs = map (t: {
            targets = [t.url];
            labels = {
              service = t.name;
              __param_module = t.module or "http_2xx";
            };
          }) blackboxTargets;
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
        {
          job_name = "blackbox_exporter";
          static_configs = [{targets = ["127.0.0.1:${toString config.my.services.blackbox-exporter.port}"];}];
        }
      ];
    };

    grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = config.my.services.grafana.port;
          domain = "grafana.pegasus.lan";
          root_url = "http://grafana.pegasus.lan/";
          serve_from_sub_path = false;
        };
        unified_alerting = {
          enabled = true;
        };
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
        alerting.rules.settings = {
          apiVersion = 1;
          groups = [
            {
              orgId = 1;
              name = "service-health";
              folder = "Alerts";
              interval = "1m";
              rules = [
                {
                  uid = "service-down";
                  title = "Service Down";
                  condition = "C";
                  data = [
                    {
                      refId = "A";
                      relativeTimeRange = {
                        from = 300;
                        to = 0;
                      };
                      datasourceUid = "prometheus_default";
                      model = {
                        expr = "probe_success";
                        intervalMs = 60000;
                        maxDataPoints = 43200;
                      };
                    }
                    {
                      refId = "B";
                      relativeTimeRange = {
                        from = 300;
                        to = 0;
                      };
                      datasourceUid = "__expr__";
                      model = {
                        type = "reduce";
                        expression = "A";
                        reducer = "last";
                        conditions = [
                          {
                            type = "query";
                            evaluator = {
                              type = "gt";
                              params = [0];
                            };
                          }
                        ];
                      };
                    }
                    {
                      refId = "C";
                      relativeTimeRange = {
                        from = 300;
                        to = 0;
                      };
                      datasourceUid = "__expr__";
                      model = {
                        type = "threshold";
                        expression = "B";
                        conditions = [
                          {
                            type = "query";
                            evaluator = {
                              type = "lt";
                              params = [1];
                            };
                          }
                        ];
                      };
                    }
                  ];
                  noDataState = "Alerting";
                  execErrState = "Alerting";
                  "for" = "2m";
                  labels.severity = "critical";
                  annotations = {
                    summary = "Service {{ $labels.instance }} is down";
                    description = "Blackbox probe to {{ $labels.instance }} has been failing for more than 2 minutes.";
                  };
                }
              ];
            }
            {
              orgId = 1;
              name = "nginx-errors";
              folder = "Alerts";
              interval = "1m";
              rules = [
                {
                  uid = "nginx-5xx-rate";
                  title = "High Nginx 5xx Error Rate";
                  condition = "C";
                  data = [
                    {
                      refId = "A";
                      relativeTimeRange = {
                        from = 300;
                        to = 0;
                      };
                      datasourceUid = "loki_default";
                      model = {
                        expr = ''sum(rate({job="nginx"} | regexp `"(?P<method>\\S+) (?P<path>\\S+) (?P<protocol>\\S+)" (?P<status>\\d+)` | status >= 500 [5m]))'';
                        intervalMs = 60000;
                        maxDataPoints = 43200;
                      };
                    }
                    {
                      refId = "B";
                      relativeTimeRange = {
                        from = 300;
                        to = 0;
                      };
                      datasourceUid = "__expr__";
                      model = {
                        type = "reduce";
                        expression = "A";
                        reducer = "last";
                        conditions = [
                          {
                            type = "query";
                            evaluator = {
                              type = "gt";
                              params = [0];
                            };
                          }
                        ];
                      };
                    }
                    {
                      refId = "C";
                      relativeTimeRange = {
                        from = 300;
                        to = 0;
                      };
                      datasourceUid = "__expr__";
                      model = {
                        type = "threshold";
                        expression = "B";
                        conditions = [
                          {
                            type = "query";
                            evaluator = {
                              type = "gt";
                              params = [0.5];
                            };
                          }
                        ];
                      };
                    }
                  ];
                  noDataState = "OK";
                  execErrState = "Alerting";
                  "for" = "5m";
                  labels.severity = "warning";
                  annotations = {
                    summary = "High rate of 5xx errors from Nginx";
                    description = "Nginx has been returning more than 0.5 5xx errors/sec for 5 minutes.";
                  };
                }
              ];
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
          working_directory = "/var/lib/loki/compactor";
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
          path_prefix = "/var/lib/loki";
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

        storage_config.filesystem.directory = "/var/lib/loki/chunks";
      };
    };

    promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = config.my.services.promtail.port;
          grpc_listen_port = 0;
        };
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
          {
            job_name = "nginx";
            static_configs = [
              {
                targets = ["localhost"];
                labels = {
                  job = "nginx";
                  host = "pegasus";
                  __path__ = "/var/log/nginx/access.log";
                };
              }
            ];
            pipeline_stages = [
              {
                regex = {
                  expression = ''^(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[^\]]+)\] "(?P<method>\S+) (?P<path>\S+) (?P<protocol>[^"]+)" (?P<status>\d+) (?P<body_bytes_sent>\d+) "(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)" "(?P<vhost>[^"]*)" (?P<request_time>\S+)$'';
                };
              }
              {
                labels = {
                  remote_addr = null;
                  method = null;
                  status = null;
                  vhost = null;
                };
              }
              # Bot / LLM user-agent detection
              {
                regex = {
                  source = "http_user_agent";
                  expression = "(?i)(?P<bot_match>GPTBot|ChatGPT-User|ClaudeBot|Claude-Web|Anthropic|CCBot|Google-Extended|Googlebot|Bingbot|Bytespider|Amazonbot|FacebookBot|Applebot|DuckDuckBot|Yandex|Sogou|PetalBot|SemrushBot|AhrefsBot|MJ12bot|DotBot|BLEXBot|DataForSeoBot|serpstatbot|Barkrowler|nmap|nikto|sqlmap|dirbuster|masscan|zgrab|python-requests|Go-http-client|curl|wget|scrapy|httpclient)";
                };
              }
              {
                template = {
                  source = "bot_type";
                  template = ''{{ if .bot_match }}bot{{ else }}human{{ end }}'';
                };
              }
              {
                labels = {
                  bot_type = null;
                  bot_match = null;
                };
              }
            ];
          }
          {
            job_name = "nginx-error";
            static_configs = [
              {
                targets = ["localhost"];
                labels = {
                  job = "nginx-error";
                  host = "pegasus";
                  __path__ = "/var/log/nginx/error.log";
                };
              }
            ];
          }
          {
            job_name = "modsecurity";
            static_configs = [
              {
                targets = ["localhost"];
                labels = {
                  job = "modsecurity";
                  host = "pegasus";
                  __path__ = "/var/log/nginx/modsec_audit.log";
                };
              }
            ];
          }
        ];
      };
    };
  };

  # Generate Telegram contact point from agenix secret before Grafana starts
  systemd.services.grafana.preStart = lib.mkAfter ''
    ${telegramContactPointScript}
  '';

  # Allow promtail to read nginx log files
  users.users.promtail.extraGroups = ["nginx"];
}
