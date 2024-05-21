{ inputs, pkgs, ... }: {
  imports = [ ./firefox.nix ./rofi/rofi.nix ];
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
  # exec-once = wl-paste -t text --watch clipman store --no-persist
  systemd.user.services.clipboard = {
    Unit = { Description = "start clipboard daemon"; };
    Install = { WantedBy = [ "hyprland-session.target" ]; };
    Service = {
      ExecStart =
        "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store --no-persist";
    };
  };

}
