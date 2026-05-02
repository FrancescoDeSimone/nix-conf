{common}: {
  uid = "nginx-traffic";
  title = "Nginx Traffic";
  tags = ["nginx" "traffic" "logs"];
  timezone = "browser";
  schemaVersion = 36;
  refresh = "30s";
  panels = [
    {
      title = "Nginx Active Connections";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 8;
        x = 0;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "nginx_connections_active";
          legendFormat = "Active";
        }
      ];
    }
    {
      title = "Request Rate (req/s)";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 16;
        x = 8;
        y = 0;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''sum(rate({job="nginx"} [5m]))'';
          legendFormat = "Total req/s";
        }
      ];
    }
    {
      title = "Requests by Virtual Host (5m rate)";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 24;
        x = 0;
        y = 8;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''sum by (vhost) (rate({job="nginx"} | regexp `"(?P<vhost>[^"]*)" \S+$` [5m]))'';
          legendFormat = "{{ vhost }}";
        }
      ];
    }
    {
      title = "Status Code Distribution";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 12;
        x = 0;
        y = 16;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''sum by (status) (rate({job="nginx"} | regexp `" (?P<status>\d)\d\d ` [5m]))'';
          legendFormat = "{{ status }}xx";
        }
      ];
    }
    {
      title = "Error Requests (4xx + 5xx)";
      type = "timeseries";
      gridPos = {
        h = 8;
        w = 12;
        x = 12;
        y = 16;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''sum(rate({job="nginx"} | regexp `" (?P<status>\d+) ` | status >= 400 [5m]))'';
          legendFormat = "Errors/s";
        }
      ];
    }
    {
      title = "Top 15 Client IPs (last 1h)";
      type = "table";
      gridPos = {
        h = 10;
        w = 12;
        x = 0;
        y = 24;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''topk(15, sum by (remote_addr) (count_over_time({job="nginx"} [$__range])))'';
          instant = true;
          legendFormat = "{{ remote_addr }}";
        }
      ];
      transformations = [
        {
          id = "organize";
          options = {
            renameByName = {
              remote_addr = "Client IP";
              Value = "Requests";
            };
          };
        }
      ];
    }
    {
      title = "Top 15 Requested Paths (last 1h)";
      type = "table";
      gridPos = {
        h = 10;
        w = 12;
        x = 12;
        y = 24;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''topk(15, sum by (path) (count_over_time({job="nginx"} | regexp `"(?P<method>\S+) (?P<path>[^?\s]+)` [$__range])))'';
          instant = true;
        }
      ];
      transformations = [
        {
          id = "organize";
          options = {
            renameByName = {
              path = "Path";
              Value = "Requests";
            };
          };
        }
      ];
    }
    {
      title = "Live Nginx Access Logs";
      type = "logs";
      gridPos = {
        h = 10;
        w = 24;
        x = 0;
        y = 34;
      };
      datasource = common.lokiDatasource;
      targets = [
        {
          expr = ''{job="nginx"}'';
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
