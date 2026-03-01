{ pkgs
, config
, ...
}: {
  services.sonarr = {
    enable = true;
    openFirewall = false;
    settings.server.port = config.my.services.sonarr.port;
    user = "thinkcentre";
  };
}
