{
  inputs,
  pkgs,
  ...
}: {
  imports = [./hyprland.nix ./foot.nix];
  home.packages = with pkgs; [
    swaycons
    telegram-desktop
    fira-code-symbols
    wf-recorder
    grimblast
    libva-utils
    wmctrl
    wl-clipboard
    clipman
    swaybg
    slurp
    nwg-displays
    grim
    fira-code
    wev
    ydotool
  ];
  fonts.fontconfig.enable = true;

  systemd.user.services.clipboard = {
    Unit = {Description = "start clipboard daemon";};
    Install = {WantedBy = ["hyprland-session.target"];};
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store --max-items=10000";
    };
  };
}
