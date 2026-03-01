{ pkgs, ... }: {
  imports = [ ./foot.nix ./sway.nix ./portal.nix ./waybar/default.nix ./clipboard.nix ];
  home.packages = with pkgs; [
    swaycons
    fira-code-symbols
    wf-recorder
    brightnessctl
    grimblast
    woomer
    libva-utils
    wmctrl
    wl-clipboard
    swaybg
    slurp
    nwg-displays
    grim
    fira-code
    wev
    ydotool
  ];
  fonts.fontconfig.enable = true;
}
