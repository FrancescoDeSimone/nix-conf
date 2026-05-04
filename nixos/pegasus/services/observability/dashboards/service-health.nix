{ common }:
{
  uid = "service-health";
  title = "Service Health";
  tags = [
    "services"
    "health"
    "blackbox"
  ];
  timezone = "browser";
  schemaVersion = 36;
  refresh = "30s";
  panels = [
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
          calcs = [ "lastNotNull" ];
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
          calcs = [ "lastNotNull" ];
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
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults = {
        color.mode = "fixed";
        color.fixedColor = "red";
      };
    }
  ];
}
