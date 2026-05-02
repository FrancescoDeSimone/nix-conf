{common}: {
  uid = "bot-activity";
  title = "Bot & LLM Activity";
  tags = ["bot" "llm" "security" "nginx"];
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
          expr = ''sum(rate({job="nginx", bot_type="bot"} [5m]))'';
          legendFormat = "Bot";
        }
        {
          expr = ''sum(rate({job="nginx", bot_type="human"} [5m]))'';
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
}
