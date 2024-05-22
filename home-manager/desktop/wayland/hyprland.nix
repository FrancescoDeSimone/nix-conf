{ pkgs, ... }:
let
  rofi_menu = pkgs.writeShellScriptBin "rofi_menu" ''
    XDG_DATA_DIRS=/usr/local/share:/usr/share:/home/fdesi/.nix-profile/share:/nix/var/nix/profiles/default/share:/home/fdesi/.nix-profile/share:/nix/var/nix/profiles/default/share
    XDG_DATA_HOME=/home/fdesi/.local/share
    $HOME/.nix-profile/bin/rofi -show drun
  '';
in
{
  imports = [ ./hyperland/default.nix ./waybar/default.nix ];

  systemd.user.services.waybar = {
    Unit = { Description = "waybar unit"; };
    Install = { WantedBy = [ "hyprland-session.target" ]; };
    Service = { ExecStart = "${pkgs.waybar}/bin/waybar"; };
  };

  home.packages = with pkgs; [ rofi_menu ];
}
