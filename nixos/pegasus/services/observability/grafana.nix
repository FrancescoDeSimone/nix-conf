{
  config,
  private,
  pkgs,
  lib,
  ...
}: let
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
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = config.my.services.grafana.port;
        domain = "grafana.${private.nginx.internalDomain}";
        root_url = "https://grafana.${private.nginx.internalDomain}/";
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
          {
            orgId = 1;
            name = "host-health-alerts";
            folder = "Alerts";
            interval = "2m";
            rules = [
              {
                uid = "host-disk-space-low";
                title = "Host Disk Space Low";
                condition = "C";
                data = [
                  {
                    refId = "A";
                    relativeTimeRange = {
                      from = 900;
                      to = 0;
                    };
                    datasourceUid = "prometheus_default";
                    model = {
                      expr = ''(node_filesystem_avail_bytes{job="node",fstype!~"tmpfs|squashfs"} / node_filesystem_size_bytes{job="node",fstype!~"tmpfs|squashfs"}) * 100'';
                      intervalMs = 60000;
                      maxDataPoints = 43200;
                    };
                  }
                  {
                    refId = "B";
                    relativeTimeRange = {
                      from = 900;
                      to = 0;
                    };
                    datasourceUid = "__expr__";
                    model = {
                      type = "reduce";
                      expression = "A";
                      reducer = "last";
                    };
                  }
                  {
                    refId = "C";
                    relativeTimeRange = {
                      from = 900;
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
                            params = [15];
                          };
                        }
                      ];
                    };
                  }
                ];
                noDataState = "OK";
                execErrState = "Alerting";
                "for" = "15m";
                labels.severity = "warning";
                annotations = {
                  summary = "Low disk space on {{ $labels.device }}";
                  description = "Filesystem '{{ $labels.mountpoint }}' on device '{{ $labels.device }}' has less than 15% space available.";
                };
              }
              {
                uid = "host-memory-high";
                title = "Host High Memory Usage";
                condition = "C";
                data = [
                  {
                    refId = "A";
                    relativeTimeRange = {
                      from = 900;
                      to = 0;
                    };
                    datasourceUid = "prometheus_default";
                    model = {
                      expr = ''(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100'';
                      intervalMs = 60000;
                      maxDataPoints = 43200;
                    };
                  }
                  {
                    refId = "B";
                    relativeTimeRange = {
                      from = 900;
                      to = 0;
                    };
                    datasourceUid = "__expr__";
                    model = {
                      type = "reduce";
                      expression = "A";
                      reducer = "last";
                    };
                  }
                  {
                    refId = "C";
                    relativeTimeRange = {
                      from = 900;
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
                            params = [10];
                          };
                        }
                      ];
                    };
                  }
                ];
                noDataState = "OK";
                execErrState = "Alerting";
                "for" = "10m";
                labels.severity = "warning";
                annotations = {
                  summary = "High memory usage on {{ $labels.instance }}";
                  description = "Available memory on {{ $labels.instance }} is less than 10% for 10 minutes.";
                };
              }
              {
                uid = "host-systemd-unit-failed";
                title = "Host Systemd Unit Failed";
                condition = "C";
                data = [
                  {
                    refId = "A";
                    relativeTimeRange = {
                      from = 600;
                      to = 0;
                    };
                    datasourceUid = "prometheus_default";
                    model = {
                      expr = ''node_systemd_unit_state{state="failed"}'';
                      intervalMs = 60000;
                      maxDataPoints = 43200;
                    };
                  }
                  {
                    refId = "B";
                    relativeTimeRange = {
                      from = 600;
                      to = 0;
                    };
                    datasourceUid = "__expr__";
                    model = {
                      type = "reduce";
                      expression = "A";
                      reducer = "last";
                    };
                  }
                  {
                    refId = "C";
                    relativeTimeRange = {
                      from = 600;
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
                            type = "eq";
                            params = [1];
                          };
                        }
                      ];
                    };
                  }
                ];
                noDataState = "OK";
                execErrState = "Alerting";
                "for" = "5m";
                labels.severity = "critical";
                annotations = {
                  summary = "Systemd unit {{ $labels.name }} failed";
                  description = "The systemd unit '{{ $labels.name }}' on {{ $labels.instance }} has entered a failed state.";
                };
              }
            ];
          }
          {
            orgId = 1;
            name = "security-alerts";
            folder = "Alerts";
            interval = "5m";
            rules = [
              {
                uid = "fail2ban-high-ban-rate";
                title = "High Fail2ban Ban Rate";
                condition = "C";
                data = [
                  {
                    refId = "A";
                    relativeTimeRange = {
                      from = 900;
                      to = 0;
                    };
                    datasourceUid = "loki_default";
                    model = {
                      expr = ''sum by (host) (count_over_time({unit="fail2ban.service"} |= "Ban" [15m]))'';
                      intervalMs = 60000;
                      maxDataPoints = 43200;
                    };
                  }
                  {
                    refId = "B";
                    relativeTimeRange = {
                      from = 900;
                      to = 0;
                    };
                    datasourceUid = "__expr__";
                    model = {
                      type = "reduce";
                      expression = "A";
                      reducer = "last";
                    };
                  }
                  {
                    refId = "C";
                    relativeTimeRange = {
                      from = 900;
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
                            params = [5];
                          };
                        }
                      ];
                    };
                  }
                ];
                noDataState = "OK";
                execErrState = "Alerting";
                "for" = "0m";
                labels.severity = "warning";
                annotations = {
                  summary = "High rate of Fail2ban bans";
                  description = "Host {{ $labels.host }} has banned more than 5 IPs in the last 15 minutes.";
                };
              }
            ];
          }
          {
            orgId = 1;
            name = "test-alerts";
            folder = "Alerts";
            interval = "1m";
            rules = [
              {
                uid = "test-notification-alert";
                title = "Test Notification";
                condition = "B";
                data = [
                  {
                    refId = "A";
                    relativeTimeRange = {
                      from = 60;
                      to = 0;
                    };
                    datasourceUid = "prometheus_default";
                    model = {
                      expr = "vector(1)";
                      intervalMs = 60000;
                      maxDataPoints = 1;
                    };
                  }
                  {
                    refId = "B";
                    relativeTimeRange = {
                      from = 60;
                      to = 0;
                    };
                    datasourceUid = "__expr__";
                    model = {
                      type = "threshold";
                      expression = "A";
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
                ];
                noDataState = "OK";
                execErrState = "OK";
                "for" = "0m";
                labels.severity = "info";
                annotations = {
                  summary = "Grafana Test Notification";
                  description = "This is a test alert to verify that notifications are working correctly.";
                };
              }
            ];
          }
        ];
      };
    };
  };

  systemd.services.grafana.preStart = lib.mkAfter ''
    ${telegramContactPointScript}
  '';
}
