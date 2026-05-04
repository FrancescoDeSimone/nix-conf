{config, ...}: {
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = config.my.services.promtail.port;
        grpc_listen_port = 0;
      };
      clients = [
        {url = "http://localhost:${toString config.my.services.loki.port}/loki/api/v1/push";}
      ];
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

  users.users.promtail.extraGroups = ["nginx"];
}
