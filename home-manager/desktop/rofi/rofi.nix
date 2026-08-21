{pkgs, ...}: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi.override {
      plugins = with pkgs; [
        rofi-calc
        rofi-top
        rofi-vpn
      ];
    };
    pass.enable = true;
    pass.package = pkgs.rofi-pass-wayland;
    pass.stores = ["$HOME/.config/.password-store"];
    # Use the selected entry's filename as the username when the entry has no
    # explicit user: line (rofi-pass otherwise falls back to $USER / whoami).
    pass.extraConfig = "default_user=:filename";
    extraConfig.modi = "drun,ssh,calc,top,filebrowser";
    theme = "~/.nix-profile/share/rofi/themes/Arc-Dark.rasi";
    terminal = "${pkgs.foot}/bin/foot";
  };
  catppuccin.rofi.enable = false;
}
