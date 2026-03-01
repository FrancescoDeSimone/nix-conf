{ pkgs, ... }: {
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      sway = {
        default = [ "wlr" "gtk" ];
      };
      common = {
        default = [ "wlr" "gtk" ];
      };
    };
  };
}
