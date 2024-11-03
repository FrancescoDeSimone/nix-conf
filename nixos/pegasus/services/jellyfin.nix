{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "thinkcentre";
    # package = pkgs.jellyfin.override {
    #   jellyfin-web = pkgs.jellyfin-web.overrideAttrs (oldAttrs: {
    #     patches = [
    #       (pkgs.fetchpatch {
    #         url =
    #           "https://github.com/jellyfin/jellyfin-web/compare/v${oldAttrs.version}...FrancescoDeSimone:jellyfin-web:intros.diff";
    #         hash = "sha256-ehjsGAGSy8QL/O/gSdOhwhVJJBT6ljqdHTlct4NxiOY=";
    #       })
    #     ];
    #   });
    # };
  };
}
