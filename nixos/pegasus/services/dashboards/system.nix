{common}: {
  uid = "system-overview";
  title = "Pegasus System";
  tags = ["system"];
  timezone = "browser";
  schemaVersion = 36;
  templating.list = [
    {
      name = "unit";
      label = "Systemd Unit";
      type = "query";
      datasource = common.lokiDatasource;
      query = ''label_values({job="systemd-journal"}, unit)'';
      refresh = 2;
      includeAll = true;
      allValue = ".*";
      multi = true;
      sort = 1;
    }
  ];
  panels = [
    {
      title = "CPU Usage (5m)";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 12;
        x = 0;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = ''100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'';
          legendFormat = "{{instance}}";
        }
      ];
    }
    {
      title = "Memory Usage";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 12;
        x = 12;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100)";
          legendFormat = "Used %";
        }
      ];
    }
    {
      title = "Disk Usage (Root)";
      type = "stat";
      gridPos = {
        h = 6;
        w = 12;
        x = 0;
        y = 8;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = ''100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)'';
          instant = true;
        }
      ];
      options = {
        colorMode = "value";
        graphMode = "none";
        textMode = "value";
        reduceOptions = {
          calcs = ["lastNotNull"];
        };
      };
      fieldConfig.defaults = {
        unit = "percent";
        decimals = 1;
      };
    }
    {
      title = "/data Usage";
      type = "stat";
      gridPos = {
        h = 6;
        w = 12;
        x = 12;
        y = 8;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = ''100 - ((node_filesystem_avail_bytes{mountpoint="/data"} / node_filesystem_size_bytes{mountpoint="/data"}) * 100)'';
          instant = true;
        }
      ];
      options = {
        colorMode = "value";
        graphMode = "none";
        textMode = "value";
        reduceOptions = {
          calcs = ["lastNotNull"];
        };
      };
      fieldConfig.defaults = {
        unit = "percent";
        decimals = 1;
      };
    }
    {
      title = "System Load";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 24;
        x = 0;
        y = 16;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "node_load1";
          legendFormat = "Load 1m";
        }
      ];
    }
    {
      title = "Journal Log Volume";
      type = "timeseries";
      gridPos = {
        h = 6;
        w = 24;
        x = 0;
        y = 24;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''sum by (unit) (rate({job="systemd-journal", unit=~"$unit"} [5m]))'';
          legendFormat = "{{ unit }}";
        }
      ];
      fieldConfig.defaults.custom = {
        fillOpacity = 30;
        stacking.mode = "normal";
      };
    }
    {
      title = "Journal Logs";
      type = "logs";
      gridPos = {
        h = 14;
        w = 24;
        x = 0;
        y = 30;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''{job="systemd-journal", unit=~"$unit"}'';
        }
      ];
      options = {
        showTime = true;
        sortOrder = "Descending";
        enableLogDetails = true;
        showLabels = true;
      };
    }
  ];
}
