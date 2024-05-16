{ inputs, pkgs, ... }: {
  imports = [ ./firefox.nix ];
  home.packages = with pkgs; [
    nerdfonts
    fira-code-nerdfont
    swaycons
    telegram-desktop
    fira-code-symbols
    brave
    xdragon
    wl-clipboard
    clipman
    slurp
    grim
    fira-code
    wev
    ydotool
    tauon
  ];
  fonts.fontconfig.enable = true;
}
