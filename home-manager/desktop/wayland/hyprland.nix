{ pkgs, ... }: {
  imports = [ ./hyperland/default.nix ./waybar/default.nix ];

  systemd.user.services.waybar = {
    Unit = { Description = "waybar unit"; };
    Install = { WantedBy = [ "hyprland-session.target" ]; };
    Service = { ExecStart = "${pkgs.waybar}/bin/waybar"; };
  };

  home.packages = with pkgs; [ ];
}
