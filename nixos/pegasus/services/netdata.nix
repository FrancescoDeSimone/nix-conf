{config, ...}: {
  services.netdata = {
    enable = true;
    config.global = {
      "memory mode" = "ram";
      "error log" = "syslog";
      "access log" = "none";
    };
  };

  networking.firewall.allowedTCPPorts = [config.my.services.netdata.port];
}