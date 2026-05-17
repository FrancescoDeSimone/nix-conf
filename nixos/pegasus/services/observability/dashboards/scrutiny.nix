{common}: {
  uid = "scrutiny-disk-health";
  title = "Disk Health - Scrutiny";
  tags = [
    "scrutiny"
    "disk"
    "smart"
    "storage"
  ];
  timezone = "browser";
  schemaVersion = 39;
  version = 1;
  refresh = "5m";
  time = {
    from = "now-6h";
    to = "now";
  };
  panels = [
    {
      type = "row";
      title = "Overview";
      gridPos = {
        h = 1;
        w = 24;
        x = 0;
        y = 0;
      };
    }
    {
      title = "Total Devices";
      type = "stat";
      gridPos = {
        h = 4;
        w = 4;
        x = 0;
        y = 1;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "count(scrutiny_device_status)";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = ["lastNotNull"];
      };
      fieldConfig.defaults = {
        unit = "short";
        decimals = 0;
      };
    }
    {
      title = "Healthy Devices";
      type = "stat";
      gridPos = {
        h = 4;
        w = 4;
        x = 4;
        y = 1;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "count(scrutiny_device_status == 0)";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = ["lastNotNull"];
      };
      fieldConfig.defaults = {
        unit = "short";
        decimals = 0;
      };
    }
    {
      title = "Failed Devices";
      type = "stat";
      gridPos = {
        h = 4;
        w = 4;
        x = 8;
        y = 1;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "sum(scrutiny_device_status)";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = ["lastNotNull"];
      };
      fieldConfig.defaults = {
        unit = "short";
        decimals = 0;
      };
      fieldConfig.defaults.thresholds = {
        mode = "absolute";
        steps = [
          {
            color = "green";
            value = null;
          }
          {
            color = "red";
            value = 1;
          }
        ];
      };
    }
    {
      type = "row";
      title = "Devices";
      gridPos = {
        h = 1;
        w = 24;
        x = 0;
        y = 5;
      };
    }
    {
      title = "Disk Status";
      type = "stat";
      gridPos = {
        h = 8;
        w = 12;
        x = 0;
        y = 6;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "scrutiny_device_status";
          instant = true;
          legendFormat = "{{device_name}} {{model_name}}";
        }
      ];
      options = {
        colorMode = "value";
        graphMode = "none";
        textMode = "value_and_name";
        reduceOptions = {
          values = false;
          calcs = ["lastNotNull"];
          fields = "";
        };
      };
      fieldConfig.defaults = {
        unit = "short";
        decimals = 0;
        mappings = [
          {
            type = "value";
            options = {
              "0" = {
                text = "PASS";
                color = "green";
              };
              "1" = {
                text = "FAIL";
                color = "red";
              };
            };
          }
        ];
      };
    }
    {
      title = "Disk Capacity";
      type = "bargauge";
      gridPos = {
        h = 8;
        w = 12;
        x = 12;
        y = 6;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "scrutiny_device_capacity_bytes";
          instant = true;
          legendFormat = "{{device_name}}";
        }
      ];
      options = {
        displayMode = "gradient";
        orientation = "horizontal";
        minV = 0;
        showUnfilled = true;
        valueMode = "color";
        reduceOptions = {
          values = false;
          calcs = ["lastNotNull"];
          fields = "";
        };
      };
      fieldConfig.defaults = {
        unit = "bytes";
        decimals = 1;
      };
    }
    {
      type = "row";
      title = "Temperature & Age";
      gridPos = {
        h = 1;
        w = 24;
        x = 0;
        y = 14;
      };
    }
    {
      title = "Temperature (°C)";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 12;
        x = 0;
        y = 15;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "scrutiny_smart_temperature_celsius";
          legendFormat = "{{device_name}}";
        }
      ];
      options = {
        legend = {
          displayMode = "table";
          placement = "bottom";
          showLegend = true;
          calcs = ["lastNotNull"];
        };
        tooltip = {
          mode = "single";
          sort = "none";
        };
      };
      fieldConfig.defaults = {
        unit = "celsius";
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
              value = 50;
            }
            {
              color = "red";
              value = 60;
            }
          ];
        };
        custom = {
          lineWidth = 2;
          fillOpacity = 20;
        };
      };
    }
    {
      title = "Power-On Hours (Years)";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 12;
        x = 12;
        y = 15;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "scrutiny_smart_power_on_hours / 24 / 365";
          legendFormat = "{{device_name}}";
        }
      ];
      options = {
        legend = {
          displayMode = "table";
          placement = "bottom";
          showLegend = true;
          calcs = ["lastNotNull"];
        };
        tooltip = {
          mode = "single";
          sort = "none";
        };
      };
      fieldConfig.defaults = {
        unit = "years";
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
              value = 5;
            }
            {
              color = "red";
              value = 7;
            }
          ];
        };
        custom = {
          lineWidth = 2;
          fillOpacity = 20;
        };
      };
    }
  ];
}
