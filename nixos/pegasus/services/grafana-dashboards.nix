{pkgs, ...}: let
  common = {
    datasource = {
      type = "prometheus";
      uid = "prometheus_default";
    };
    lokiDatasource = {
      type = "loki";
      uid = "loki_default";
    };
  };

  # ---------------------------------------------------------------------------
  # Existing dashboards
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # New dashboards
  # ---------------------------------------------------------------------------

  serviceHealthDashboard = {
    uid = "service-health";
    title = "Service Health";
    tags = ["services" "health" "blackbox"];
    timezone = "browser";
    schemaVersion = 36;
    refresh = "30s";
    panels = [
      # Row: Service status grid
      {
        title = "Service Status";
        type = "stat";
        gridPos = {
          h = 6;
          w = 24;
          x = 0;
          y = 0;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = "probe_success";
            legendFormat = "{{ instance }}";
            instant = true;
          }
        ];
        options = {
          colorMode = "background";
          graphMode = "none";
          textMode = "name";
          reduceOptions = {
            calcs = ["lastNotNull"];
          };
        };
        fieldConfig = {
          defaults = {
            mappings = [
              {
                type = "value";
                options = {
                  "0" = {
                    text = "DOWN";
                    color = "red";
                  };
                  "1" = {
                    text = "UP";
                    color = "green";
                  };
                };
              }
            ];
            thresholds = {
              mode = "absolute";
              steps = [
                {
                  color = "red";
                  value = null;
                }
                {
                  color = "green";
                  value = 1;
                }
              ];
            };
          };
        };
      }
      # Row: Response times
      {
        title = "Probe Duration (seconds)";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 24;
          x = 0;
          y = 6;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = "probe_duration_seconds";
            legendFormat = "{{ instance }}";
          }
        ];
        fieldConfig.defaults.unit = "s";
      }
      # Row: Uptime percentage (24h)
      {
        title = "Uptime % (24h)";
        type = "stat";
        gridPos = {
          h = 6;
          w = 24;
          x = 0;
          y = 14;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = "avg_over_time(probe_success[24h]) * 100";
            legendFormat = "{{ instance }}";
            instant = true;
          }
        ];
        options = {
          colorMode = "background";
          graphMode = "none";
          reduceOptions = {
            calcs = ["lastNotNull"];
          };
        };
        fieldConfig = {
          defaults = {
            unit = "percent";
            decimals = 2;
            thresholds = {
              mode = "absolute";
              steps = [
                {
                  color = "red";
                  value = null;
                }
                {
                  color = "orange";
                  value = 95;
                }
                {
                  color = "green";
                  value = 99;
                }
              ];
            };
          };
        };
      }
      # Row: HTTP status code from probes
      {
        title = "Probe HTTP Status Code";
        type = "table";
        gridPos = {
          h = 8;
          w = 24;
          x = 0;
          y = 20;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = "probe_http_status_code";
            legendFormat = "{{ instance }}";
            instant = true;
            format = "table";
          }
        ];
        transformations = [
          {
            id = "organize";
            options = {
              excludeByName = {
                Time = true;
                __name__ = true;
                job = true;
              };
              renameByName = {
                instance = "Service";
                Value = "Status Code";
              };
            };
          }
        ];
      }
      # Row: Systemd unit states
      {
        title = "Failed Systemd Units";
        type = "stat";
        gridPos = {
          h = 6;
          w = 24;
          x = 0;
          y = 28;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = ''node_systemd_unit_state{state="failed"} == 1'';
            legendFormat = "{{ name }}";
            instant = true;
          }
        ];
        options = {
          colorMode = "background";
          graphMode = "none";
          textMode = "name";
          reduceOptions.calcs = ["lastNotNull"];
        };
        fieldConfig.defaults = {
          color.mode = "fixed";
          color.fixedColor = "red";
        };
      }
    ];
  };

  nginxTrafficDashboard = {
    uid = "nginx-traffic";
    title = "Nginx Traffic";
    tags = ["nginx" "traffic" "logs"];
    timezone = "browser";
    schemaVersion = 36;
    refresh = "30s";
    panels = [
      # Row: Request rate
      {
        title = "Request Rate (req/s)";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 24;
          x = 0;
          y = 0;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum(rate({job="nginx"} [5m]))'';
            legendFormat = "Total req/s";
          }
        ];
      }
      # Row: Requests by vhost
      {
        title = "Requests by Virtual Host (5m rate)";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 24;
          x = 0;
          y = 8;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum by (vhost) (rate({job="nginx"} | regexp `"(?P<vhost>[^"]*)" \S+$` [5m]))'';
            legendFormat = "{{ vhost }}";
          }
        ];
      }
      # Row: Status code distribution
      {
        title = "Status Code Distribution";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 12;
          x = 0;
          y = 16;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum by (status) (rate({job="nginx"} | regexp `" (?P<status>\d)\d\d ` [5m]))'';
            legendFormat = "{{ status }}xx";
          }
        ];
      }
      # Row: 4xx and 5xx errors
      {
        title = "Error Requests (4xx + 5xx)";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 12;
          x = 12;
          y = 16;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum(rate({job="nginx"} | regexp `" (?P<status>\d+) ` | status >= 400 [5m]))'';
            legendFormat = "Errors/s";
          }
        ];
      }
      # Row: Top client IPs
      {
        title = "Top 15 Client IPs (last 1h)";
        type = "table";
        gridPos = {
          h = 10;
          w = 12;
          x = 0;
          y = 24;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''topk(15, sum by (remote_addr) (count_over_time({job="nginx"} [1h])))'';
            instant = true;
            legendFormat = "{{ remote_addr }}";
          }
        ];
        transformations = [
          {
            id = "organize";
            options = {
              renameByName = {
                remote_addr = "Client IP";
                Value = "Requests";
              };
            };
          }
        ];
      }
      # Row: Top paths
      {
        title = "Top 15 Requested Paths (last 1h)";
        type = "table";
        gridPos = {
          h = 10;
          w = 12;
          x = 12;
          y = 24;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''topk(15, sum by (path) (count_over_time({job="nginx"} | regexp `"(?P<method>\S+) (?P<path>\S+)` [1h])))'';
            instant = true;
          }
        ];
        transformations = [
          {
            id = "organize";
            options = {
              renameByName = {
                path = "Path";
                Value = "Requests";
              };
            };
          }
        ];
      }
      # Row: Live log stream
      {
        title = "Live Nginx Access Logs";
        type = "logs";
        gridPos = {
          h = 10;
          w = 24;
          x = 0;
          y = 34;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''{job="nginx"}'';
          }
        ];
        options = {
          showTime = true;
          sortOrder = "Descending";
          enableLogDetails = true;
        };
      }
    ];
  };

  botActivityDashboard = {
    uid = "bot-activity";
    title = "Bot & LLM Activity";
    tags = ["bot" "llm" "security" "nginx"];
    timezone = "browser";
    schemaVersion = 36;
    refresh = "1m";
    panels = [
      # Row: Bot vs Human traffic
      {
        title = "Bot vs Human Requests";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 12;
          x = 0;
          y = 0;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum(rate({job="nginx", bot_type="bot"} [5m]))'';
            legendFormat = "Bot";
          }
          {
            expr = ''sum(rate({job="nginx", bot_type="human"} [5m]))'';
            legendFormat = "Human";
          }
        ];
      }
      # Row: Bot percentage
      {
        title = "Bot Traffic % (last 1h)";
        type = "stat";
        gridPos = {
          h = 8;
          w = 6;
          x = 12;
          y = 0;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum(count_over_time({job="nginx", bot_type="bot"} [1h])) / sum(count_over_time({job="nginx"} [1h])) * 100'';
            legendFormat = "Bot %";
            instant = true;
          }
        ];
        options = {
          colorMode = "background";
          graphMode = "none";
          reduceOptions.calcs = ["lastNotNull"];
        };
        fieldConfig.defaults = {
          unit = "percent";
          decimals = 1;
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "yellow";
                value = 30;
              }
              {
                color = "red";
                value = 60;
              }
            ];
          };
        };
      }
      # Row: Total bot count (1h)
      {
        title = "Total Bot Requests (last 1h)";
        type = "stat";
        gridPos = {
          h = 8;
          w = 6;
          x = 18;
          y = 0;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum(count_over_time({job="nginx", bot_type="bot"} [1h]))'';
            legendFormat = "Bot Requests";
            instant = true;
          }
        ];
        options = {
          colorMode = "value";
          graphMode = "none";
          reduceOptions.calcs = ["lastNotNull"];
        };
        fieldConfig.defaults.thresholds = {
          mode = "absolute";
          steps = [
            {
              color = "green";
              value = null;
            }
            {
              color = "yellow";
              value = 500;
            }
            {
              color = "red";
              value = 2000;
            }
          ];
        };
      }
      # Row: Top bot user agents
      {
        title = "Top Bot User-Agents (last 1h)";
        type = "table";
        gridPos = {
          h = 10;
          w = 12;
          x = 0;
          y = 8;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''topk(20, sum by (bot_match) (count_over_time({job="nginx", bot_type="bot"} [1h])))'';
            instant = true;
          }
        ];
        transformations = [
          {
            id = "organize";
            options = {
              renameByName = {
                bot_match = "Bot User-Agent";
                Value = "Requests";
              };
            };
          }
        ];
      }
      # Row: IPs sending bot traffic
      {
        title = "Top IPs Sending Bot Traffic (last 1h)";
        type = "table";
        gridPos = {
          h = 10;
          w = 12;
          x = 12;
          y = 8;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''topk(20, sum by (remote_addr) (count_over_time({job="nginx", bot_type="bot"} [1h])))'';
            instant = true;
          }
        ];
        transformations = [
          {
            id = "organize";
            options = {
              renameByName = {
                remote_addr = "Client IP";
                Value = "Bot Requests";
              };
            };
          }
        ];
      }
      # Row: Bot traffic by vhost
      {
        title = "Bot Requests by Virtual Host";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 24;
          x = 0;
          y = 18;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum by (vhost) (rate({job="nginx", bot_type="bot"} [5m]))'';
            legendFormat = "{{ vhost }}";
          }
        ];
      }
      # Row: Live bot log stream
      {
        title = "Live Bot Traffic Logs";
        type = "logs";
        gridPos = {
          h = 10;
          w = 24;
          x = 0;
          y = 26;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''{job="nginx", bot_type="bot"}'';
          }
        ];
        options = {
          showTime = true;
          sortOrder = "Descending";
          enableLogDetails = true;
        };
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
          cp ${pkgs.writeText "service-health.json" (builtins.toJSON serviceHealthDashboard)} $out/service-health.json
          cp ${pkgs.writeText "nginx-traffic.json" (builtins.toJSON nginxTrafficDashboard)} $out/nginx-traffic.json
          cp ${pkgs.writeText "bot-activity.json" (builtins.toJSON botActivityDashboard)} $out/bot-activity.json
        '';
      }
    ];
  };
}
