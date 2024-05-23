{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = [ pkgs.rofi-calc ];
    pass.enable = true;
    pass.package = pkgs.rofi-pass-wayland;
    pass.stores = [ "$HOME/.config/.password-store" ];
    extraConfig.modi = "drun,ssh";
    catppuccin.enable = false;
    terminal = "${pkgs.foot}/bin/foot";
  };
}
