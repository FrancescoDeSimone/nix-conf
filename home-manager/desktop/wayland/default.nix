{ inputs, pkgs, ... }: {
  imports = [ ./hyprland.nix ./foot.nix ];
  home.packages = with pkgs; [
    nerdfonts
    fira-code-nerdfont
    swaycons
    telegram-desktop
    fira-code-symbols
    brave
    xdragon
    playerctl
    wf-recorder
    grimblast
    libva-utils
    wmctrl
    wl-clipboard
    clipman
    swaybg
    slurp
    grim
    fira-code
    wev
    ydotool
  ];
  fonts.fontconfig.enable = true;
}
