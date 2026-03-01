{ config, ... }: {
  imports = [ ./modules.nix ./style.nix ];
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "graphical-session.target";
    };
  };
}
