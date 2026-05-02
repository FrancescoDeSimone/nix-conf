{ common }:
{
  uid = "adguard-home";
  title = "AdGuard Home";
  tags = [ "adguard" "dns" "network" "security" ];
  timezone = "browser";
  schemaVersion = 39;
  version = 1;
  refresh = "30s";
  time = {
    from = "now-24h";
    to = "now";
  };
  panels = [
    {
      type = "row";
      title = "Status";
      gridPos = { h = 1; w = 24; x = 0; y = 0; };
    }
    {
      title = "AdGuard Running";
      type = "stat";
      gridPos = { h = 4; w = 4; x = 0; y = 1; };
      datasource = common.datasource;
      targets = [
        {
          expr = "adguard_running";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults = {
        mappings = [
          {
            type = "value";
            options = {
              "0" = { text = "STOPPED"; color = "red"; };
              "1" = { text = "RUNNING"; color = "green"; };
            };
          }
        ];
        min = 0;
        max = 1;
      };
    }
    {
      title = "Protection Enabled";
      type = "stat";
      gridPos = { h = 4; w = 4; x = 4; y = 1; };
      datasource = common.datasource;
      targets = [
        {
          expr = "adguard_protection_enabled";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults = {
        mappings = [
          {
            type = "value";
            options = {
              "0" = { text = "DISABLED"; color = "orange"; };
              "1" = { text = "ENABLED"; color = "green"; };
            };
          }
        ];
        min = 0;
        max = 1;
      };
    }
    {
      title = "DHCP Available";
      type = "stat";
      gridPos = { h = 4; w = 4; x = 8; y = 1; };
      datasource = common.datasource;
      targets = [
        {
          expr = "adguard_dhcp_available";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults = {
        mappings = [
          {
            type = "value";
            options = {
              "0" = { text = "UNAVAILABLE"; color = "gray"; };
              "1" = { text = "AVAILABLE"; color = "blue"; };
            };
          }
        ];
        min = 0;
        max = 1;
      };
    }
    {
      title = "Exporter Up";
      type = "stat";
      gridPos = { h = 4; w = 4; x = 12; y = 1; };
      datasource = common.datasource;
      targets = [
        {
          expr = "adguard_exporter_up";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults = {
        mappings = [
          {
            type = "value";
            options = {
              "0" = { text = "DOWN"; color = "red"; };
              "1" = { text = "UP"; color = "green"; };
            };
          }
        ];
        min = 0;
        max = 1;
      };
    }
    {
      title = "HTTP Probe";
      type = "stat";
      gridPos = { h = 4; w = 4; x = 16; y = 1; };
      datasource = common.datasource;
      targets = [
        {
          expr = ''probe_success{instance="adguard"}'';
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults = {
        mappings = [
          {
            type = "value";
            options = {
              "0" = { text = "DOWN"; color = "red"; };
              "1" = { text = "UP"; color = "green"; };
            };
          }
        ];
        min = 0;
        max = 1;
      };
    }
    {
      title = "Scrape Duration";
      type = "stat";
      gridPos = { h = 4; w = 4; x = 20; y = 1; };
      datasource = common.datasource;
      targets = [
        {
          expr = "adguard_exporter_scrape_duration_seconds";
          instant = true;
        }
      ];
      options = {
        colorMode = "value";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults = {
        unit = "s";
        decimals = 2;
        color.mode = "thresholds";
        thresholds = {
          mode = "absolute";
          steps = [
            { value = 0; color = "green"; }
            { value = 2; color = "orange"; }
            { value = 5; color = "red"; }
          ];
        };
      };
    }
    {
      type = "row";
      title = "DNS Overview";
      gridPos = { h = 1; w = 24; x = 0; y = 5; };
    }
    {
      title = "Total Queries (24h)";
      type = "stat";
      gridPos = { h = 4; w = 4; x = 0; y = 6; };
      datasource = common.datasource;
      targets = [
        {
          expr = "adguard_dns_queries_total";
          instant = true;
        }
      ];
      options = {
        colorMode = "value";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults.unit = "short";
    }
    {
      title = "Blocked Queries (24h)";
      type = "stat";
      gridPos = { h = 4; w = 4; x = 4; y = 6; };
      datasource = common.datasource;
      targets = [
        {
          expr = "adguard_blocked_filtering_total";
          instant = true;
        }
      ];
      options = {
        colorMode = "value";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults.unit = "short";
    }
    {
      title = "Blocked Ratio";
      type = "stat";
      gridPos = { h = 4; w = 4; x = 8; y = 6; };
      datasource = common.datasource;
      targets = [
        {
          expr = "adguard_blocked_filtering_total / clamp_min(adguard_dns_queries_total, 1) * 100";
          instant = true;
        }
      ];
      options = {
        colorMode = "value";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults = {
        unit = "percent";
        decimals = 2;
      };
    }
    {
      title = "Avg Processing Time";
      type = "stat";
      gridPos = { h = 4; w = 4; x = 12; y = 6; };
      datasource = common.datasource;
      targets = [
        {
          expr = "adguard_avg_processing_time";
          instant = true;
        }
      ];
      options = {
        colorMode = "value";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults = {
        unit = "ms";
        decimals = 2;
      };
    }
    {
      title = "Parental Replaced (24h)";
      type = "stat";
      gridPos = { h = 4; w = 4; x = 16; y = 6; };
      datasource = common.datasource;
      targets = [
        {
          expr = "adguard_replaced_parental";
          instant = true;
        }
      ];
      options = {
        colorMode = "value";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults.unit = "short";
    }
    {
      title = "Scrape Errors (24h)";
      type = "stat";
      gridPos = { h = 4; w = 4; x = 20; y = 6; };
      datasource = common.datasource;
      targets = [
        {
          expr = "increase(adguard_exporter_scrape_errors_total[24h])";
          instant = true;
        }
      ];
      options = {
        colorMode = "value";
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults = {
        unit = "short";
        color.mode = "thresholds";
        thresholds = {
          mode = "absolute";
          steps = [
            { value = 0; color = "green"; }
            { value = 1; color = "red"; }
          ];
        };
      };
    }
    {
      type = "row";
      title = "Activity";
      gridPos = { h = 1; w = 24; x = 0; y = 10; };
    }
    {
      title = "DNS Query Rate";
      type = "timeseries";
      gridPos = { h = 8; w = 12; x = 0; y = 11; };
      datasource = common.datasource;
      targets = [
        {
          expr = "rate(adguard_dns_queries_total[5m])";
          legendFormat = "Queries/sec";
        }
        {
          expr = "rate(adguard_blocked_filtering_total[5m])";
          legendFormat = "Blocked/sec";
        }
      ];
      fieldConfig.defaults = {
        unit = "ops";
        custom = {
          drawStyle = "line";
          fillOpacity = 10;
          lineWidth = 2;
          showPoints = "never";
        };
      };
      options = {
        legend = {
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
      };
    }
    {
      title = "DNS Query Types";
      type = "timeseries";
      gridPos = { h = 8; w = 12; x = 12; y = 11; };
      datasource = common.datasource;
      targets = [
        {
          expr = "sum by (type) (rate(adguard_query_type_total[5m]))";
          legendFormat = "{{type}}";
        }
      ];
      fieldConfig.defaults.custom = {
        drawStyle = "line";
        fillOpacity = 8;
        lineWidth = 2;
        showPoints = "never";
      };
      options = {
        legend = {
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
      };
    }
    {
      title = "Block Reasons";
      type = "timeseries";
      gridPos = { h = 8; w = 12; x = 0; y = 19; };
      datasource = common.datasource;
      targets = [
        {
          expr = "sum by (reason) (rate(adguard_query_reason_total[5m]))";
          legendFormat = "{{reason}}";
        }
      ];
      fieldConfig.defaults = {
        unit = "ops";
        custom = {
          drawStyle = "line";
          fillOpacity = 8;
          lineWidth = 2;
          showPoints = "never";
        };
      };
      options = {
        legend = {
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
      };
    }
    {
      title = "Top Client / Reason Activity";
      type = "timeseries";
      gridPos = { h = 8; w = 12; x = 12; y = 19; };
      datasource = common.datasource;
      targets = [
        {
          expr = "topk(10, sum by (client, reason) (rate(adguard_query_client_reason_total[5m])))";
          legendFormat = "{{client}} - {{reason}}";
        }
      ];
      fieldConfig.defaults = {
        unit = "ops";
        custom = {
          drawStyle = "line";
          fillOpacity = 8;
          lineWidth = 1;
          showPoints = "never";
        };
      };
      options = {
        legend = {
          displayMode = "list";
          placement = "right";
          showLegend = true;
        };
      };
    }
    {
      type = "row";
      title = "Top Lists";
      gridPos = { h = 1; w = 24; x = 0; y = 27; };
    }
    {
      title = "Top Queried Domains";
      type = "table";
      gridPos = { h = 10; w = 8; x = 0; y = 28; };
      datasource = common.datasource;
      targets = [
        {
          expr = "topk(10, adguard_top_queried_domain_total)";
          instant = true;
          legendFormat = "{{domain}}";
        }
      ];
      options = {
        showHeader = true;
        sortBy = [ { desc = true; displayName = "Value"; } ];
      };
    }
    {
      title = "Top Blocked Domains";
      type = "table";
      gridPos = { h = 10; w = 8; x = 8; y = 28; };
      datasource = common.datasource;
      targets = [
        {
          expr = "topk(10, adguard_top_blocked_domain_total)";
          instant = true;
          legendFormat = "{{domain}}";
        }
      ];
      options = {
        showHeader = true;
        sortBy = [ { desc = true; displayName = "Value"; } ];
      };
    }
    {
      title = "Top Clients";
      type = "table";
      gridPos = { h = 10; w = 8; x = 16; y = 28; };
      datasource = common.datasource;
      targets = [
        {
          expr = "topk(10, adguard_top_client_total)";
          instant = true;
          legendFormat = "{{client}}";
        }
      ];
      options = {
        showHeader = true;
        sortBy = [ { desc = true; displayName = "Value"; } ];
      };
    }
    {
      type = "row";
      title = "Upstreams & Probe";
      gridPos = { h = 1; w = 24; x = 0; y = 38; };
    }
    {
      title = "Upstream Query Rate";
      type = "timeseries";
      gridPos = { h = 8; w = 12; x = 0; y = 39; };
      datasource = common.datasource;
      targets = [
        {
          expr = "sum by (upstream) (rate(adguard_query_upstream_total[5m]))";
          legendFormat = "{{upstream}}";
        }
      ];
      fieldConfig.defaults = {
        unit = "ops";
        custom = {
          drawStyle = "line";
          fillOpacity = 8;
          lineWidth = 2;
          showPoints = "never";
        };
      };
      options = {
        legend = {
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
      };
    }
    {
      title = "Upstream p95 Latency";
      type = "timeseries";
      gridPos = { h = 8; w = 12; x = 12; y = 39; };
      datasource = common.datasource;
      targets = [
        {
          expr = "histogram_quantile(0.95, sum by (le, upstream) (rate(adguard_upstream_latency_seconds_bucket[5m]))) * 1000";
          legendFormat = "{{upstream}}";
        }
      ];
      fieldConfig.defaults = {
        unit = "ms";
        custom = {
          drawStyle = "line";
          fillOpacity = 8;
          lineWidth = 2;
          showPoints = "never";
        };
      };
      options = {
        legend = {
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
      };
    }
    {
      title = "Upstream Avg Response Time";
      type = "timeseries";
      gridPos = { h = 8; w = 12; x = 0; y = 47; };
      datasource = common.datasource;
      targets = [
        {
          expr = "adguard_upstream_avg_response_time_seconds * 1000";
          legendFormat = "{{upstream}}";
        }
      ];
      fieldConfig.defaults = {
        unit = "ms";
        custom = {
          drawStyle = "line";
          fillOpacity = 8;
          lineWidth = 2;
          showPoints = "never";
        };
      };
      options = {
        legend = {
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
      };
    }
    {
      title = "HTTP Probe Duration";
      type = "timeseries";
      gridPos = { h = 8; w = 12; x = 12; y = 47; };
      datasource = common.datasource;
      targets = [
        {
          expr = ''probe_duration_seconds{instance="adguard"}'';
          legendFormat = "Probe Duration";
        }
      ];
      fieldConfig.defaults = {
        unit = "s";
        custom = {
          drawStyle = "line";
          fillOpacity = 8;
          lineWidth = 2;
          showPoints = "never";
        };
      };
    }
  ];
}
