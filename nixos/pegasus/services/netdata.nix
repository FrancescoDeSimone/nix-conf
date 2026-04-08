{config, pkgs, ...}: {
  services.netdata = {
    enable = true;
    package = pkgs.netdata.override {withCloudUi = true;};
    config.global = {
      "memory mode" = "ram";
      "error log" = "syslog";
      "access log" = "none";
    };
  };

  networking.firewall.allowedTCPPorts = [config.my.services.netdata.port];
}