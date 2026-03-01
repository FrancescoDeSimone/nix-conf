{ config, ... }: {
  services.jellyseerr = {
    enable = true;
    port = config.my.services.jellyseerr.port;
    openFirewall = false;
  };
}
