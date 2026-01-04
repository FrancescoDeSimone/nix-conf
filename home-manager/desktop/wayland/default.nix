{pkgs, ...}: {
  imports = [./foot.nix ./sway.nix ./portal.nix ./waybar/default.nix];
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
    clipvault
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
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.clipvault}/bin/clipvault store --max-entries 10000 --min-entry-length 2";
    };
  };
}
