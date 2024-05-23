{ inputs, pkgs, ... }: {
  imports = [ ./dunst.nix ./firefox.nix ./rofi/rofi.nix ./pass.nix ];
  home.packages = with pkgs; [
    nerdfonts
    fira-code-nerdfont
    swaycons
    telegram-desktop
    fira-code-symbols
    brave
    xdragon
    mpv
    wl-clipboard
    clipman
    slurp
    obs-studio
    grim
    fira-code
    wev
    ydotool
    sshuttle
    supersonic
    pavucontrol
  ];
  fonts.fontconfig.enable = true;
  systemd.user.services.clipboard = {
    Unit = { Description = "start clipboard daemon"; };
    Install = { WantedBy = [ "hyprland-session.target" ]; };
    Service = {
      ExecStart =
        "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store --max-items=1000000";
    };
  };

}
