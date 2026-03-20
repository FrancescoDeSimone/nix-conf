{
  outputs,
  pkgs,
  lib,
  ...
}:
let
  freedoom = pkgs.fetchurl {
    url = "https://github.com/freedoom/freedoom/releases/download/v0.13.0/freedoom-0.13.0.zip";
    sha256 = "0ncgd2wqv1yxfklg6kbgaixkrn8ryjqxqsvzzfs07r9w7r7jd6rz";
  };

  brutaldoom = pkgs.fetchurl {
    url = "https://github.com/BLOODWOLF333/Brutal-Doom-Community-Expansion/releases/download/v21.50.0/brutalv21.50.0.pk3";
    sha256 = "1dv9wgjqy7cam1hmq6kz66dxnkwbzymx1ql13dpd1mbvivxmgnmb";
  };

  brutaldoom-launcher = pkgs.writeShellScriptBin "brutaldoom" ''
    mkdir -p ~/.local/share/games/doom
    if [ ! -f ~/.local/share/games/doom/freedoom2.wad ]; then
      TEMP_DIR=$(mktemp -d)
      unzip -o "${freedoom}" -d "$TEMP_DIR"
      cp "$TEMP_DIR"/freedoom-0.13.0/*.wad ~/.local/share/games/doom/
      rm -rf "$TEMP_DIR"
    fi
    if [ ! -f ~/.local/share/games/doom/brutalv21.50.0.pk3 ]; then
      cp "${brutaldoom}" ~/.local/share/games/doom/brutalv21.50.0.pk3
    fi
    ${pkgs.gzdoom}/bin/gzdoom -IWAD ~/.local/share/games/doom/freedoom2.wad -file ~/.local/share/games/doom/brutalv21.50.0.pk3
  '';

  kbd-backlight = pkgs.writeShellScriptBin "kbd-backlight" ''
    DEV="rgb:kbd_backlight"
    STEP=10
    case "$1" in
      up)   brightnessctl -d "$DEV" s ''${STEP}%+ ;;
      down) brightnessctl -d "$DEV" s ''${STEP}%- ;;
      toggle)
        CUR=$(brightnessctl -d "$DEV" g)
        if [ "$CUR" -eq 0 ]; then
          brightnessctl -d "$DEV" s 50%
        else
          brightnessctl -d "$DEV" s 0
        fi
        ;;
    esac
    ${pkgs.swayosd}/bin/swayosd-client --kbd-brightness raise
  '';
in
{
  imports = [
    ./desktop/default.nix
    ./cli/default.nix
    ./desktop/gaming/gamescope.nix
    ./desktop/gaming/retroarch.nix
    ./desktop/wayland/default.nix
    ./cli/programming/default.nix
  ];
  home.packages = with pkgs; [
    jellyfin-tui
    unstable.freetube
    ayugram-desktop
    opencode
    gzdoom
    brutaldoom-launcher
  ];
  home = {
    username = "fdesi";
    homeDirectory = "/home/fdesi";
    stateVersion = "25.11";
  };
  wayland.windowManager.sway.config.keybindings = lib.mkOptionDefault {
    "--release XF86KbdBrightnessUp" = "exec ${kbd-backlight}/bin/kbd-backlight up";
    "--release XF86KbdBrightnessDown" = "exec ${kbd-backlight}/bin/kbd-backlight down";
    "--release XF86KbdLightOnOff" = "exec ${kbd-backlight}/bin/kbd-backlight toggle";
    "--release XF86LightsToggle" = "exec ${kbd-backlight}/bin/kbd-backlight toggle";
  };

  programs.waybar.settings.mainBar.temperature = lib.mkOptionDefault {
    "chip" = "zenpower";
    "format" = " {icon} {temperatureC}°C ";
    "format-icons" = [ "" ];
    "interval" = 30;
    "tooltip-format" = "{all}";
  };
}
