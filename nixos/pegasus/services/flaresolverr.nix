{
  config,
  pkgs,
  ...
}: {
  services.flaresolverr = {
    enable = true;
    port = config.my.services.flaresolverr.port;
    openFirewall = false;
    package = pkgs.unstable.flaresolverr;
  };
}
