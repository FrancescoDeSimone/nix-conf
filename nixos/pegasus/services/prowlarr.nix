{ pkgs
, config
, ...
}: {
  services.prowlarr = {
    package = pkgs.unstable.prowlarr;
    enable = true;
    settings.server.port = config.my.services.prowlarr.port;
    openFirewall = false;
  };
}
