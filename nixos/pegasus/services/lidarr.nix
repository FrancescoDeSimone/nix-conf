{config, ...}: {
  services.lidarr = {
    enable = true;
    openFirewall = false;
    settings.server.port = config.my.services.lidarr.port;
    user = "thinkcentre";
  };
}
