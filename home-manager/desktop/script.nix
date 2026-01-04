{
  pkgs,
  lib,
  ...
}: let
  clipvault_rofi = pkgs.writeShellScriptBin "clipvault_rofi" ''
    #!/usr/bin/env bash

    # Dependencies path setup
    PATH=$PATH:${lib.makeBinPath [
      pkgs.coreutils
      pkgs.gawk
      pkgs.findutils
      pkgs.gnugrep
      pkgs.clipvault
      pkgs.wl-clipboard
      pkgs.wtype
    ]}

    rofi_list()
    {
        list=$(clipvault list)

        # Ensure thumbnail directory exists
        thumbnails_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/clipvault/thumbs"
        [ -d "$thumbnails_dir" ] || mkdir -p "$thumbnails_dir"

        # Delete thumbnails that are no longer in the DB
        find "$thumbnails_dir" -type f | while IFS= read -r thumbnail; do
            item_id=$(basename "''${thumbnail%.*}")
            if ! grep -q "^''${item_id}\s\[\[ binary data" <<< "$list"; then
                rm "$thumbnail"
            fi
        done

        # Generates thumbnails
        read -r -d "" prog << EOF
    /^[0-9]+\s<meta http-equiv=/ { next }
    match(\$0, /^([0-9]+)\s(\[\[\sbinary.*(jpg|jpeg|png|bmp|webp|tif|gif).*)/, grp) {
        image = grp[1]"."grp[3]
        system("[[ -f ''${thumbnails_dir}/"image" ]] || echo " grp[1] " | clipvault get >''${thumbnails_dir}/"image)
        print grp[2]"\000icon\037''${thumbnails_dir}/"image"\037info\037"grp[1]"\n"
        next
    }
    match(\$0, /^([0-9]+)\s(.*)/, grp) {
        print grp[2]"\000info\037"grp[1]"\n"
        next
    }
    1
    EOF

        echo "$list" | gawk "$prog"
    }

    case $ROFI_RETV in
        # Display entries on startup
        0)
            echo -en "\000use-hot-keys\037true\n"
            rofi_list
            ;;
        # Handle regular select (kb-accept-entry, default <Enter>)
        1)
            if [ ! "$ROFI_INFO" = "" ]; then
                clipvault get "$ROFI_INFO" | wl-copy
            fi
            exit
            ;;
        # Handle entry deletion (kb-delete-entry, default <S-Delete>)
        3)
            if [ ! "$ROFI_INFO" = "" ]; then
                clipvault delete "$ROFI_INFO"
            fi
            rofi_list
            ;;
        # Handle custom keybind 1 (kb-custom-1) - delete all entries
        10)
            clipvault clear
            ;;
        # Handle custom keybind 2 (kb-custom-2) - attempt to type directly
        11)
            if [ ! "$ROFI_INFO" = "" ]; then
                coproc {
                    wtype "$(clipvault get "$ROFI_INFO")"
                }
            fi
            exit
            ;;
    esac
  '';

  catall = pkgs.writeShellScriptBin "catall" ''
     filename=$1
      find * ! -name $filename -type f -exec sh -c 'file --mime "$1" | grep -q "text/" && { echo "File:
    $1"; cat "$1"; }' _ {} \; >  $filename
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
    catall
    clipvault_rofi
  ];
}
