{pkgs, ...}: let
  rofi_menu = pkgs.writeShellScriptBin "rofi_menu" ''
    # Preserving your XDG setup for non-NixOS application discovery
    export XDG_DATA_DIRS="/var/lib/snapd/desktop:/usr/local/share:/usr/share:/home/fdesi/.nix-profile/share/applications:/nix/var/nix/profiles/default/share:/home/fdesi/.nix-profile/share:/nix/var/nix/profiles/default/share"
    export XDG_DATA_HOME="/home/fdesi/.local/share"

    if command -v rofi &> /dev/null; then
      ROFI_CMD="rofi"
    else
      ROFI_CMD="${pkgs.rofi}/bin/rofi"
    fi

    $ROFI_CMD -show drun -sorting-method fzf -sort -i
  '';

  prev_player = pkgs.writeShellScriptBin "prev_player" ''
    ${pkgs.playerctl}/bin/playerctl previous
  '';

  playpause_player = pkgs.writeShellScriptBin "playpause_player" ''
    ${pkgs.playerctl}/bin/playerctl play-pause
  '';

  next_player = pkgs.writeShellScriptBin "next_player" ''
    ${pkgs.playerctl}/bin/playerctl next
  '';

  bgr = pkgs.writeShellScriptBin "bgr" ''
    nohup $1 > /dev/null  2>&1 &
  '';

  lockscreen = pkgs.writeShellScriptBin "lockscreen" ''
    # Hybrid Check: Prefer /usr/local/bin for manually compiled Hyprlock (Ubuntu)
    if [ -x "/usr/local/bin/hyprlock" ]; then
      HYPRLOCK="/usr/local/bin/hyprlock"
    elif [ -x "/usr/bin/hyprlock" ]; then
      HYPRLOCK="/usr/bin/hyprlock"
    else
      HYPRLOCK="${pkgs.hyprlock}/bin/hyprlock"
    fi

    $HYPRLOCK -c ~/.config/hypr/hyprlock.conf -q
  '';

  changegroupactiveormovefocus = pkgs.writeShellScriptBin "changegroupactiveormovefocus" ''
    # 1. Resolve Hyprctl: System (Ubuntu/GPU compat) -> Nix (NixOS)
    if [ -x "/usr/local/bin/hyprctl" ]; then
      hypr="/usr/local/bin/hyprctl"
    elif [ -x "/usr/bin/hyprctl" ]; then
      hypr="/usr/bin/hyprctl"
    else
      hypr="${pkgs.hyprland}/bin/hyprctl"
    fi

    # 2. Resolve JQ: System -> Nix
    if [ -x "/usr/bin/jq" ]; then
      jq="/usr/bin/jq"
    else
      jq="${pkgs.jq}/bin/jq"
    fi

    # 3. Execution Logic
    activewindow="$($hypr activewindow -j)"
    readonly activewindow

    if ! $jq -e '.grouped[]' <<< "$activewindow" >/dev/null; then
      $hypr dispatch movefocus "$1"
    elif [[ "$1" == l ]] && $jq -e '.address == .grouped[0]' <<< "$activewindow" >/dev/null;
    then
      $hypr dispatch movefocus l
    elif [[ "$1" == l ]];
    then
      $hypr dispatch changegroupactive b
    elif [[ "$1" == r ]] && $jq -e '.address == .grouped[-1]' <<< "$activewindow" >/dev/null;
    then
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
    jq
    playerctl
    hyprland
    hyprlock
  ];
}
