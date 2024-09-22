{pkgs, ...}: let
  rofi_menu = pkgs.writeShellScriptBin "rofi_menu" ''
    XDG_DATA_DIRS="/var/lib/snapd/desktop:/usr/local/share:/usr/share:/home/fdesi/.nix-profile/share/applications:/nix/var/nix/profiles/default/share:/home/fdesi/.nix-profile/share:/nix/var/nix/profiles/default/share"
    XDG_DATA_HOME="/home/fdesi/.local/share"
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

  bgr = pkgs.writeShellScriptBin "bgr" ''
    nohup $1 > /dev/null  2>&1 &
  '';

  lockscreen = pkgs.writeShellScriptBin "lockscreen" ''
    /usr/local/bin/hyprlock -c ~/.config/hypr/hyprlock.conf -q
  '';
  changegroupactiveormovefocus = pkgs.writeShellScriptBin "changegroupactiveormovefocus" ''
    hypr="/usr/local/bin/hyprctl"
    activewindow="$(/usr/local/bin/hyprctl activewindow -j)"
    readonly activewindow
    if ! jq -e '.grouped[]' <<< "$activewindow" >/dev/null; then
      $hypr dispatch movefocus "$1"
    elif [[ "$1" == l ]] && /usr/bin/jq -e '.address == .grouped[0]' <<< "$activewindow" >/dev/null; then
      $hypr dispatch movefocus l
    elif [[ "$1" == l ]]; then
      $hypr dispatch changegroupactive b
    elif [[ "$1" == r ]] && /usr/bin/jq -e '.address == .grouped[-1]' <<< "$activewindow" >/dev/null; then
      $hypr dispatch movefocus r
    else
      $hypr dispatch changegroupactive f
    fi
  '';
in {
  home.packages = with pkgs; [
    rofi_menu
    lockscreen
    playpause_player
    next_player
    prev_player
    changegroupactiveormovefocus
    bgr
  ];
}
