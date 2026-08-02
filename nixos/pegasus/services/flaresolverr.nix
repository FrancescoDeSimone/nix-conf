{config, ...}: {
  services.flaresolverr.enable = true;
  networking.firewall.allowedTCPPorts = [config.my.services.flaresolverr.port];
}
