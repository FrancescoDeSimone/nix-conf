{ common }:
{
  uid = "tailnet-overview";
  title = "Headscale & Tailscale";
  tags = [ "headscale" "tailscale" "tailnet" ];
  timezone = "browser";
  schemaVersion = 36;
  refresh = "30s";
  panels = [
    {
      title = "Headscale Probe";
      type = "stat";
      gridPos = {
        h = 6;
        w = 8;
        x = 0;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = ''probe_success{instance="headscale"}'';
          instant = true;
          legendFormat = "Headscale";
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "none";
        textMode = "name";
        reduceOptions.calcs = [ "lastNotNull" ];
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
      title = "Headscale Probe Duration";
      type = "timeseries";
      gridPos = {
        h = 6;
        w = 16;
        x = 8;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = ''probe_duration_seconds{instance="headscale"}'';
          legendFormat = "headscale";
        }
      ];
      fieldConfig.defaults.unit = "s";
    }
    {
      title = "Tailnet Nodes Online";
      type = "stat";
      gridPos = {
        h = 6;
        w = 8;
        x = 0;
        y = 6;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = ''headscale_tailnet_nodes_total{state="online"}'';
          instant = true;
          legendFormat = "Online";
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "none";
        textMode = "value_and_name";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
    }
    {
      title = "Tailnet Nodes Offline";
      type = "stat";
      gridPos = {
        h = 6;
        w = 8;
        x = 8;
        y = 6;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = ''headscale_tailnet_nodes_total{state="offline"}'';
          instant = true;
          legendFormat = "Offline";
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "none";
        textMode = "value_and_name";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
    }
    {
      title = "Tailnet Metrics Scrape";
      type = "stat";
      gridPos = {
        h = 6;
        w = 8;
        x = 16;
        y = 6;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = ''headscale_tailnet_scrape_success'';
          instant = true;
          legendFormat = "Metrics";
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "none";
        textMode = "name";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults = {
        mappings = [
          {
            type = "value";
            options = {
              "0" = {
                text = "FAILED";
                color = "red";
              };
              "1" = {
                text = "OK";
                color = "green";
              };
            };
          }
        ];
      };
    }
    {
      title = "Headscale Log Rate";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 12;
        x = 0;
        y = 12;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''sum(rate({job="systemd-journal", unit="headscale.service"}[5m]))'';
          legendFormat = "headscale logs/s";
        }
      ];
    }
    {
      title = "Tailscaled Log Rate";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 12;
        x = 12;
        y = 12;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''sum(rate({job="systemd-journal", unit="tailscaled.service"}[5m]))'';
          legendFormat = "tailscaled logs/s";
        }
      ];
    }
    {
      title = "Tailnet Hosts";
      type = "table";
      gridPos = {
        h = 10;
        w = 24;
        x = 0;
        y = 20;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = ''headscale_tailnet_node_online'';
          instant = true;
          format = "table";
        }
      ];
      transformations = [
        {
          id = "labelsToFields";
          options = {
            mode = "columns";
          };
        }
        {
          id = "organize";
          options = {
            excludeByName = {
              Time = true;
              __name__ = true;
              instance = true;
              job = true;
            };
            renameByName = {
              hostname = "Hostname";
              fqdn = "FQDN";
              user = "User";
              tailnet_ip = "Tail IP";
              node_id = "Node ID";
              Value = "Online";
            };
          };
        }
      ];
      fieldConfig.defaults.custom.align = "auto";
      fieldConfig.overrides = [
        {
          matcher = {
            id = "byName";
            options = "Online";
          };
          properties = [
            {
              id = "mappings";
              value = [
                {
                  type = "value";
                  options = {
                    "0" = {
                      text = "offline";
                      color = "red";
                    };
                    "1" = {
                      text = "online";
                      color = "green";
                    };
                  };
                }
              ];
            }
          ];
        }
      ];
    }
    {
      title = "Recent Headscale Events";
      type = "logs";
      gridPos = {
        h = 12;
        w = 12;
        x = 0;
        y = 30;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''{job="systemd-journal", unit="headscale.service"}'';
        }
      ];
      options = {
        showTime = true;
        sortOrder = "Descending";
        enableLogDetails = true;
      };
    }
    {
      title = "Recent Tailscaled Events";
      type = "logs";
      gridPos = {
        h = 12;
        w = 12;
        x = 12;
        y = 30;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''{job="systemd-journal", unit="tailscaled.service"}'';
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
