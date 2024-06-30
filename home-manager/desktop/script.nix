{pkgs, ...}: let
  rofi_menu = pkgs.writeShellScriptBin "rofi_menu" ''
    XDG_DATA_DIRS=/usr/local/share:/usr/share:/home/fdesi/.nix-profile/share:/nix/var/nix/profiles/default/share:/home/fdesi/.nix-profile/share:/nix/var/nix/profiles/default/share
    XDG_DATA_HOME=/home/fdesi/.local/share
    $HOME/.nix-profile/bin/rofi -show drun -sorting-method fzf -sort -i
  '';
  prev_player = pkgs.writeShellScriptBin "prev_player" ''
    $HOME/.nix-profile/bin/playerctl previous
  '';
  playpause_player = pkgs.writeShellScriptBin "playpause_player" ''
    $HOME/.nix-profile/bin/playerctl play-pause
  '';

  next_player = pkgs.writeShellScriptBin "next_player" ''
    $HOME/.nix-profile/bin/playerctl next
  '';

  bg_run = pkgs.writeShellScriptBin "bg_run" ''
    nohup $1 > /dev/null  2>&1 &
  '';

  lockscreen = pkgs.writeShellScriptBin "lockscreen" ''
    /usr/local/bin/hyprlock -c ~/.config/hypr/hyprlock.conf -q
  '';
in {
  home.packages = with pkgs; [
    rofi_menu
    lockscreen
    playpause_player
    next_player
    prev_player
    bg_run
  ];
}
