{
  pkgs,
  config,
  ...
}: {
  services.sonarr = {
    package = pkgs.unstable.sonarr;
    enable = true;
    openFirewall = true;
    user = "thinkcentre";
  };
}
