{common}: let
  # Must stay in sync with the bot list formerly in promtail.nix.
  # Labels bot_type/bot_match no longer exist (fluent-bit ships nginx logs
  # without them), so every panel extracts them at query time instead.
  botRe = "(?i)(GPTBot|ChatGPT-User|ClaudeBot|Claude-Web|Anthropic|CCBot|Google-Extended|Googlebot|Bingbot|Bytespider|Amazonbot|FacebookBot|Applebot|DuckDuckBot|Yandex|Sogou|PetalBot|SemrushBot|AhrefsBot|MJ12bot|DotBot|BLEXBot|DataForSeoBot|serpstatbot|Barkrowler|nmap|nikto|sqlmap|dirbuster|masscan|zgrab|python-requests|Go-http-client|curl|wget|scrapy|httpclient)";
  botFilter = ''| json | http_user_agent =~ "${botRe}"'';
  humanFilter = ''| json | http_user_agent !~ "${botRe}"'';
  botExtract = ''| regexp "(?i)(?P<bot_match>${botRe})"'';
in {
  uid = "bot-activity";
  title = "Bot & LLM Activity";
  tags = [
    "bot"
    "llm"
    "security"
    "nginx"
  ];
  timezone = "browser";
  schemaVersion = 36;
  refresh = "1m";
  panels = [
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
          expr = ''sum(rate({job="nginx"} ${botFilter} [5m]))'';
          legendFormat = "Bot";
        }
        {
          expr = ''sum(rate({job="nginx"} ${humanFilter} [5m]))'';
          legendFormat = "Human";
        }
      ];
    }
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
          expr = ''sum(count_over_time({job="nginx"} ${botFilter} [1h])) / sum(count_over_time({job="nginx"} [1h])) * 100'';
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
          expr = ''sum(count_over_time({job="nginx"} ${botFilter} [1h]))'';
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
          expr = ''topk(20, sum by (bot_match) (count_over_time({job="nginx"} ${botFilter} ${botExtract} [1h])))'';
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
          expr = ''topk(20, sum by (remote_addr) (count_over_time({job="nginx"} ${botFilter} [1h])))'';
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
          expr = ''sum by (vhost) (rate({job="nginx"} ${botFilter} [5m]))'';
          legendFormat = "{{ vhost }}";
        }
      ];
    }
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
      targets = [{expr = ''{job="nginx"} ${botFilter}'';}];
      options = {
        showTime = true;
        sortOrder = "Descending";
        enableLogDetails = true;
      };
    }
    {
      title = "Ollama Status";
      type = "stat";
      gridPos = {
        h = 6;
        w = 6;
        x = 0;
        y = 36;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = ''probe_success{instance="ollama"}'';
          legendFormat = "Ollama";
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
            color = "red";
            value = null;
          }
          {
            color = "green";
            value = 1;
          }
        ];
      };
    }
    {
      title = "Ollama Probe Latency";
      type = "timeseries";
      gridPos = {
        h = 6;
        w = 18;
        x = 6;
        y = 36;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = ''probe_duration_seconds{instance="ollama"}'';
          legendFormat = "probe s";
        }
      ];
    }
    {
      title = "Ollama Logs";
      type = "logs";
      gridPos = {
        h = 10;
        w = 24;
        x = 0;
        y = 42;
      };
      datasource = common.lokiDatasource;
      targets = [{expr = ''{unit="ollama.service"}'';}];
      options = {
        showTime = true;
        sortOrder = "Descending";
        enableLogDetails = true;
      };
    }
  ];
}
