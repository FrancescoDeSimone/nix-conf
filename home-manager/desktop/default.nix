{pkgs, ...}: {
  imports = [./dunst.nix ./firefox.nix ./rofi/rofi.nix ./pass.nix ./script.nix];
  home.packages = with pkgs;
    [
      playerctl
      fira-code-symbols
      dragon-drop
      networkmanagerapplet
      fira-code
      sshuttle
      supersonic
      pavucontrol
      # unstable.freetube
      obsidian
      unstable.finamp
    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
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
