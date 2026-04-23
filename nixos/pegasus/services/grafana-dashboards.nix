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
    templating.list = [
      {
        name = "unit";
        label = "Systemd Unit";
        type = "query";
        datasource = common.lokiDatasource;
        query = ''label_values({job="systemd-journal"}, unit)'';
        refresh = 2; # on time range change
        includeAll = true;
        allValue = ".*";
        multi = true;
        sort = 1; # alphabetical asc
      }
    ];
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
            expr = ''100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'';
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
            expr = ''100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)'';
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
      # Row: Journal Logs
      {
        title = "Journal Log Volume";
        type = "timeseries";
        gridPos = {
          h = 6;
          w = 24;
          x = 0;
          y = 16;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum by (unit) (rate({job="systemd-journal", unit=~"$unit"} [5m]))'';
            legendFormat = "{{ unit }}";
          }
        ];
        fieldConfig.defaults.custom = {
          fillOpacity = 30;
          stacking.mode = "normal";
        };
      }
      {
        title = "Journal Logs";
        type = "logs";
        gridPos = {
          h = 14;
          w = 24;
          x = 0;
          y = 22;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''{job="systemd-journal", unit=~"$unit"}'';
          }
        ];
        options = {
          showTime = true;
          sortOrder = "Descending";
          enableLogDetails = true;
          showLabels = true;
        };
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
        title = "AdGuard Status";
        type = "stat";
        gridPos = {
          h = 8;
          w = 12;
          x = 0;
          y = 0;
        };
        datasource = common.datasource;
        targets = [
          {
            expr = ''probe_success{instance="adguard"}'';
            instant = true;
            legendFormat = "AdGuard";
          }
        ];
        options = {
          colorMode = "background";
          graphMode = "none";
          textMode = "name";
          reduceOptions.calcs = ["lastNotNull"];
        };
        fieldConfig.defaults = {
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
        };
      }
      {
        title = "AdGuard Probe Duration";
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
            expr = ''probe_duration_seconds{instance="adguard"}'';
            legendFormat = "Probe Duration";
          }
        ];
        fieldConfig.defaults.unit = "s";
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

  # Media dashboard disabled: exportarr module not available in nixpkgs
  # Re-enable when exportarr or native prometheus endpoints are available
  # mediaDashboard = { ... };

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
            expr = ''topk(15, sum by (remote_addr) (count_over_time({job="nginx"} [$__range])))'';
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
            expr = ''topk(15, sum by (path) (count_over_time({job="nginx"} | regexp `"(?P<method>\S+) (?P<path>[^?\s]+)` [$__range])))'';
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

  fail2banDashboard = {
    uid = "fail2ban";
    title = "Fail2ban";
    tags = ["fail2ban" "security"];
    timezone = "browser";
    schemaVersion = 36;
    refresh = "1m";
    panels = [
      # Row: Active bans estimate
      {
        title = "Active Bans (estimated)";
        type = "stat";
        gridPos = {
          h = 6;
          w = 8;
          x = 0;
          y = 0;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum(count_over_time({unit="fail2ban.service"} |= "Ban" != "Unban" [$__range])) - sum(count_over_time({unit="fail2ban.service"} |= "Unban" [$__range]))'';
            instant = true;
          }
        ];
        options = {
          colorMode = "background";
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
              value = 5;
            }
            {
              color = "red";
              value = 20;
            }
          ];
        };
      }
      # Row: Total bans in range
      {
        title = "Total Bans";
        type = "stat";
        gridPos = {
          h = 6;
          w = 8;
          x = 8;
          y = 0;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum(count_over_time({unit="fail2ban.service"} |= "Ban" != "Unban" [$__range]))'';
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
              value = 50;
            }
            {
              color = "red";
              value = 200;
            }
          ];
        };
      }
      # Row: Total unbans in range
      {
        title = "Total Unbans";
        type = "stat";
        gridPos = {
          h = 6;
          w = 8;
          x = 16;
          y = 0;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum(count_over_time({unit="fail2ban.service"} |= "Unban" [$__range]))'';
            instant = true;
          }
        ];
        options = {
          colorMode = "value";
          graphMode = "none";
          reduceOptions.calcs = ["lastNotNull"];
        };
        fieldConfig.defaults.color = {
          mode = "fixed";
          fixedColor = "blue";
        };
      }
      # Row: Ban rate over time
      {
        title = "Ban Rate";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 24;
          x = 0;
          y = 6;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum(rate({unit="fail2ban.service"} |= "Ban" != "Unban" [5m]))'';
            legendFormat = "Bans/s";
          }
          {
            expr = ''sum(rate({unit="fail2ban.service"} |= "Unban" [5m]))'';
            legendFormat = "Unbans/s";
          }
        ];
      }
      # Row: Bans by jail
      {
        title = "Bans by Jail";
        type = "timeseries";
        gridPos = {
          h = 8;
          w = 24;
          x = 0;
          y = 14;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''sum by (jail) (rate({unit="fail2ban.service"} |= "Ban" != "Unban" | regexp `\[(?P<jail>[^\]]+)\]` [5m]))'';
            legendFormat = "{{ jail }}";
          }
        ];
      }
      # Row: Recent ban events log
      {
        title = "Recent Ban/Unban Events";
        type = "logs";
        gridPos = {
          h = 12;
          w = 24;
          x = 0;
          y = 22;
        };
        datasource = common.lokiDatasource;
        targets = [
          {
            expr = ''{unit="fail2ban.service"} |~ "Ban|Unban"'';
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
          cp ${pkgs.writeText "service-health.json" (builtins.toJSON serviceHealthDashboard)} $out/service-health.json
          cp ${pkgs.writeText "nginx-traffic.json" (builtins.toJSON nginxTrafficDashboard)} $out/nginx-traffic.json
          cp ${pkgs.writeText "bot-activity.json" (builtins.toJSON botActivityDashboard)} $out/bot-activity.json
          cp ${pkgs.writeText "fail2ban.json" (builtins.toJSON fail2banDashboard)} $out/fail2ban.json
        '';
      }
    ];
  };
}
