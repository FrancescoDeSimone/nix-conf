{config, ...}: {
  imports = [../../../modules/nixos/lidarr-deemix];

  my.services.lidarr-deemix = {
    enable = true;
    deemixUrl = "http://127.0.0.1:${toString config.my.services.deemix.port}";
  };

  services.lidarr = {
    enable = true;
    openFirewall = false;
    settings.server.port = config.my.services.lidarr.port;
    user = "thinkcentre";
    group = "lidarr";
  };
}
