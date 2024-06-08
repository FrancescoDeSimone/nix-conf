{ pkgs, ... }:
let
  rofi_menu = pkgs.writeShellScriptBin "rofi_menu" ''
    XDG_DATA_DIRS=/usr/local/share:/usr/share:/home/fdesi/.nix-profile/share:/nix/var/nix/profiles/default/share:/home/fdesi/.nix-profile/share:/nix/var/nix/profiles/default/share
    XDG_DATA_HOME=/home/fdesi/.local/share
    $HOME/.nix-profile/bin/rofi -show drun -sorting-method fzf -sort -i
  '';
  supersonicprev = pkgs.writeShellScriptBin "supersonicprev" ''
    $HOME/.nix-profile/bin/playerctl previous
  '';
  supersonicplaypause = pkgs.writeShellScriptBin "supersonicplaypause" ''
    $HOME/.nix-profile/bin/playerctl play-pause
  '';

  supersonicnext = pkgs.writeShellScriptBin "supersonicnext" ''
    $HOME/.nix-profile/bin/playerctl next
  '';

  lockscreen = pkgs.writeShellScriptBin "lockscreen" ''
    /usr/local/bin/hyprlock -c ~/.config/hypr/hyprlock.conf -q
  '';
in
{
  imports = [ ./hyperland/default.nix ./waybar/default.nix ];

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

  home.packages = with pkgs; [
    rofi_menu
    lockscreen
    supersonicplaypause
    supersonicnext
    supersonicprev
  ];
}
