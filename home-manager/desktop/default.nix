{ inputs, pkgs, ... }: {
  imports = [ ./dunst.nix ./firefox.nix ./rofi/rofi.nix ./pass.nix ];
  home.packages = with pkgs; [
    nerdfonts
    fira-code-nerdfont
    swaycons
    telegram-desktop
    fira-code-symbols
    xdragon
    wl-clipboard
    clipman
    slurp
    networkmanagerapplet
    grim
    fira-code
    wev
    ydotool
    sshuttle
    supersonic
    pavucontrol
  ];
  fonts.fontconfig.enable = true;
  systemd.user.services.nm-applet = {
    Unit = { Description = "start nm-applet"; };
    Install = { WantedBy = [ "graphical.target" ]; };
    Service = { ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet"; };
  };

}
