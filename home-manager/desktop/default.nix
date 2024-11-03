{pkgs, ...}: {
  imports = [./dunst.nix ./firefox.nix ./rofi/rofi.nix ./pass.nix ./script.nix];
  home.packages = with pkgs; [
    nerdfonts
    fira-code-nerdfont
    playerctl
    telegram-desktop
    fira-code-symbols
    xdragon
    networkmanagerapplet
    fira-code
    sshuttle
    supersonic
    pavucontrol
    unstable.freetube
    obsidian
    unstable.finamp
  ];
  fonts.fontconfig.enable = true;
  systemd.user = {
    enable = true;
    services.nm-applet = {
      Unit = {Description = "start nm-applet";};
      Install = {WantedBy = ["display-manager.target"];};
      Service = {ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";};
    };
  };
}
