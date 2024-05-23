{ config, pkgs, ... }: {
  services.grafana = {
    enable = true;
    domain = "grafana.pele";
    port = 2342;
    addr = "127.0.0.1";
  };
  services.prometheus = {
    enable = true;
    port = 9001;
  };
  services.prometheus = {
    scrapeConfigs = [{
      job_name = "chrysalis";
      static_configs = [{
        targets = [
          "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
        ];
      }];
    }];

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
  };
}
