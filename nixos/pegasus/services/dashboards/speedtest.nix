{common}: {
  uid = "speedtest-tracker";
  title = "Speedtest Tracker";
  tags = ["speedtest" "network" "speedtest-tracker"];
  timezone = "browser";
  schemaVersion = 36;
  refresh = "5m";
  panels = [
    {
      title = "Download Speed";
      type = "stat";
      gridPos = {
        h = 4;
        w = 6;
        x = 0;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "avg(speedtest_tracker_download_bits)";
          legendFormat = "Download";
        }
      ];
      fieldConfig.defaults = {
        unit = "bps";
        decimals = 1;
        thresholds = {
          mode = "percentage";
          steps = [
            {
              color = "dark-red";
              value = 0;
            }
            {
              color = "dark-yellow";
              value = 60;
            }
            {
              color = "dark-green";
              value = 70;
            }
          ];
        };
      };
      options = {
        colorMode = "value";
        graphMode = "area";
        reduceOptions.calcs = ["mean"];
      };
    }
    {
      title = "Upload Speed";
      type = "stat";
      gridPos = {
        h = 4;
        w = 6;
        x = 6;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "avg(speedtest_tracker_upload_bits)";
          legendFormat = "Upload";
        }
      ];
      fieldConfig.defaults = {
        unit = "bps";
        decimals = 1;
        thresholds = {
          mode = "percentage";
          steps = [
            {
              color = "dark-red";
              value = 0;
            }
            {
              color = "dark-yellow";
              value = 70;
            }
            {
              color = "dark-green";
              value = 90;
            }
          ];
        };
      };
      options = {
        colorMode = "value";
        graphMode = "area";
        reduceOptions.calcs = ["mean"];
      };
    }
    {
      title = "Ping";
      type = "stat";
      gridPos = {
        h = 4;
        w = 6;
        x = 12;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "avg(speedtest_tracker_ping_ms)";
          legendFormat = "Ping";
        }
      ];
      fieldConfig.defaults = {
        unit = "ms";
        decimals = 1;
        thresholds = {
          mode = "percentage";
          steps = [
            {
              color = "dark-green";
              value = 0;
            }
            {
              color = "dark-yellow";
              value = 50;
            }
            {
              color = "dark-red";
              value = 100;
            }
          ];
        };
      };
      options = {
        colorMode = "value";
        graphMode = "area";
        reduceOptions.calcs = ["mean"];
      };
    }
    {
      title = "Jitter";
      type = "stat";
      gridPos = {
        h = 4;
        w = 6;
        x = 18;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "avg(speedtest_tracker_ping_jitter_ms)";
          legendFormat = "Jitter";
        }
      ];
      fieldConfig.defaults = {
        unit = "ms";
        decimals = 1;
        thresholds = {
          mode = "percentage";
          steps = [
            {
              color = "dark-green";
              value = 0;
            }
            {
              color = "dark-yellow";
              value = 50;
            }
            {
              color = "dark-red";
              value = 100;
            }
          ];
        };
      };
      options = {
        colorMode = "value";
        graphMode = "area";
        reduceOptions.calcs = ["mean"];
      };
    }
    {
      title = "Speedtest Results";
      type = "timeseries";
      gridPos = {
        h = 10;
        w = 24;
        x = 0;
        y = 4;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "speedtest_tracker_download_bits";
          legendFormat = "Download";
        }
        {
          expr = "speedtest_tracker_upload_bits";
          legendFormat = "Upload";
        }
      ];
      fieldConfig.defaults = {
        unit = "bps";
        decimals = 1;
        custom = {
          lineWidth = 1;
          fillOpacity = 30;
        };
      };
      options = {
        legend = {
          displayMode = "table";
          placement = "bottom";
        };
      };
    }
    {
      title = "Ping (ms)";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 12;
        x = 0;
        y = 14;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "speedtest_tracker_ping_ms";
          legendFormat = "Ping";
        }
      ];
      fieldConfig.defaults = {
        unit = "ms";
        decimals = 1;
        custom = {
          lineWidth = 1;
          fillOpacity = 30;
        };
      };
      options = {
        legend = {
          displayMode = "table";
          placement = "bottom";
        };
      };
    }
    {
      title = "Jitter (ms)";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 12;
        x = 12;
        y = 14;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "speedtest_tracker_ping_jitter_ms";
          legendFormat = "Jitter";
        }
      ];
      fieldConfig.defaults = {
        unit = "ms";
        decimals = 1;
        custom = {
          lineWidth = 1;
          fillOpacity = 30;
        };
      };
      options = {
        legend = {
          displayMode = "table";
          placement = "bottom";
        };
      };
    }
    {
      title = "Packet Loss (%)";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 12;
        x = 0;
        y = 22;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "speedtest_tracker_packet_loss_percent";
          legendFormat = "Packet Loss";
        }
      ];
      fieldConfig.defaults = {
        unit = "percent";
        decimals = 2;
        thresholds = {
          mode = "absolute";
          steps = [
            {
              color = "green";
              value = null;
            }
            {
              color = "yellow";
              value = 2;
            }
            {
              color = "red";
              value = 5;
            }
          ];
        };
        custom = {
          lineWidth = 1;
          fillOpacity = 30;
        };
      };
      options = {
        legend = {
          displayMode = "table";
          placement = "bottom";
        };
      };
    }
    {
      title = "Server Info";
      type = "table";
      gridPos = {
        h = 8;
        w = 12;
        x = 12;
        y = 22;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "speedtest_tracker_download_bits";
          instant = true;
          format = "table";
        }
      ];
      options = {showHeader = true;};
      transformations = [
        {
          id = "labelsToFields";
          options = {};
        }
        {
          id = "organize";
          options = {
            excludeByName = {
              Time = true;
              __name__ = true;
              job = true;
            };
            renameByName = {
              server_name = "Server";
              server_location = "Location";
              server_country = "Country";
              isp = "ISP";
              Value = "Download (bps)";
            };
          };
        }
      ];
    }
  ];
}
