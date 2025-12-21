{ pkgs, ... }: {
  imports = [ ./hyprland/default.nix ];
  # ./usr/lib/xdg-desktop-portal-hyprland
  systemd.user.services.xdg-desktop-portal-hyprland = {
    Unit = { Description = "xdg-desktop-portal-hyprland"; };
    Install = { WantedBy = [ "hyprland-session.target" ]; };
    Service = { ExecStart = "/usr/lib/xdg-desktop-portal-hyprland"; };
  };
  systemd.user.services.waybar = {
    Unit = { Description = "waybar unit"; };
    Install = { WantedBy = [ "hyprland-session.target" ]; };
    Service = { ExecStart = "${pkgs.waybar}/bin/waybar"; };
  };
}
