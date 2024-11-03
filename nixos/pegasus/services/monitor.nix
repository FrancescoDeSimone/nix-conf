{config, ...}: {
  services.grafana = {
    enable = true;
    settings.server = {
      protocol = "http";
      http_addr = "0.0.0.0";
      http_port = 3030;
    };
  };

  services.prometheus = {
    enable = true;
    port = 9090;
    exporters = {
      systemd.enable = true;
      systemd = {
        port = 9006;
      };
      process.enable = true;
      process = {
        port = 9005;
      };
      node.enable = true;
      node = {
        enabledCollectors = ["logind" "systemd" "processes"];
        port = 9002;
      };
    };

    globalConfig = {
      scrape_interval = "5s";
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
      {
        job_name = "process";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.exporters.process.port}"];
          }
        ];
      }
      {
        job_name = "systemd";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.exporters.systemd.port}"];
          }
        ];
      }
    ];
  };
}
