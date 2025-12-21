{ pkgs, ... }: {
  services.prowlarr = {
    package = pkgs.unstable.prowlarr;
    enable = true;
    openFirewall = true;
  };
}
