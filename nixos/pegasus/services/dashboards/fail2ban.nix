{ common }:
{
  uid = "fail2ban";
  title = "Fail2ban";
  tags = [ "fail2ban" "security" ];
  timezone = "browser";
  schemaVersion = 36;
  refresh = "1m";
  panels = [
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
        reduceOptions.calcs = [ "lastNotNull" ];
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
        reduceOptions.calcs = [ "lastNotNull" ];
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
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults.color = {
        mode = "fixed";
        fixedColor = "blue";
      };
    }
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
}
