{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.modules.desktop.wayland.clipboard;

  clipman-watcher = "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store --no-persist";
  clipman-picker = "${pkgs.clipman}/bin/clipman pick -t rofi";

  cliphist-rofi-img = pkgs.writeShellScriptBin "cliphist-rofi-img" ''
    #!/usr/bin/env bash
    tmp_dir="/tmp/cliphist"
    rm -rf "$tmp_dir"

    if [[ -n "$ROFI_INFO" ]]; then
        ${pkgs.cliphist}/bin/cliphist decode <<<"$ROFI_INFO" | ${pkgs.wl-clipboard}/bin/wl-copy
        exit
    elif [[ -n "$1" ]]; then
        ${pkgs.cliphist}/bin/cliphist decode <<<"$1" | ${pkgs.wl-clipboard}/bin/wl-copy
        exit
    fi

    mkdir -p "$tmp_dir"

    ${pkgs.cliphist}/bin/cliphist list | ${pkgs.gawk}/bin/gawk -v tmp_dir="$tmp_dir" -v cliphist_cmd="${pkgs.cliphist}/bin/cliphist" '
    BEGIN { FS="\t" }
    /^[0-9]+\s<meta http-equiv=/ { next }
    {
        id = $1
        content = $2
        if (match($0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp)/, grp)) {
            system("printf \"%s\\t\" " id " | " cliphist_cmd " decode >" tmp_dir "/" id "." grp[3])
            printf "%s\x00icon\x1f%s/%s.%s\x1finfo\x1f%s\n", content, tmp_dir, id, grp[3], id
        } else {
            printf "%s\x00info\x1f%s\n", content, id
        }
    }
    '
  '';

  cliphist-watcher = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
  cliphist-picker = "${config.programs.rofi.package}/bin/rofi -modi clipboard:${cliphist-rofi-img}/bin/cliphist-rofi-img -show clipboard -show-icons -theme-str 'element-icon { size: 6em; } listview { lines: 6; }'";

  clipvault-rofi-script = pkgs.writeShellScriptBin "clipvault_rofi" ''
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

        # Generates thumbnails and Formats output to hide IDs
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
        0)  echo -en "\000use-hot-keys\037true\n"
            rofi_list ;;
        1)  if [ ! "$ROFI_INFO" = "" ]; then
                clipvault get "$ROFI_INFO" | wl-copy
            fi
            exit ;;
        3)  if [ ! "$ROFI_INFO" = "" ]; then
                clipvault delete "$ROFI_INFO"
            fi
            rofi_list ;;
        10) clipvault clear ;;
        11) if [ ! "$ROFI_INFO" = "" ]; then
                coproc {
                    wtype "$(clipvault get "$ROFI_INFO")"
                }
            fi
            exit ;;
    esac
  '';

  clipvault-watcher = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.clipvault}/bin/clipvault store --max-entries 10000 --min-entry-length 2";
  clipvault-picker = "${config.programs.rofi.package}/bin/rofi -modi clipboard:${clipvault-rofi-script}/bin/clipvault_rofi -show clipboard -show-icons -theme-str 'element-icon { size: 6em; } listview { lines: 6; }'";

  selected-watcher =
    if cfg.manager == "clipman"
    then clipman-watcher
    else if cfg.manager == "cliphist"
    then cliphist-watcher
    else clipvault-watcher;

  selected-picker =
    if cfg.manager == "clipman"
    then clipman-picker
    else if cfg.manager == "cliphist"
    then cliphist-picker
    else clipvault-picker;
in {
  options.modules.desktop.wayland.clipboard = {
    manager = lib.mkOption {
      type = lib.types.enum ["clipman" "cliphist" "clipvault"];
      default = "clipvault";
      description = "Which clipboard manager to use.";
    };
  };

  config = {
    home.packages = with pkgs;
      (lib.optional (cfg.manager == "clipman") clipman)
      ++ (lib.optional (cfg.manager == "cliphist") cliphist)
      ++ (lib.optional (cfg.manager == "clipvault") clipvault)
      ++ [
        (writeShellScriptBin "clipboard-picker" ''
          ${selected-picker}
        '')
      ];

    systemd.user.services.clipboard = {
      Unit = {
        Description = "Clipboard management daemon (${cfg.manager})";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
      Service = {
        ExecStart = selected-watcher;
        Restart = "always";
        RestartSec = "2";
      };
    };
  };
}
