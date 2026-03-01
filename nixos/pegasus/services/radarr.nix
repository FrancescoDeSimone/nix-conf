{ config, ... }: {
  services.radarr = {
    enable = true;
    settings.server.port = config.my.services.radarr.port;
    openFirewall = false;
    user = "thinkcentre";
  };
}
