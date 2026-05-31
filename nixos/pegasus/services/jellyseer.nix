{config, ...}: {
  services.seerr = {
    enable = true;
    port = config.my.services.seerr.port;
    openFirewall = false;
  };
}
