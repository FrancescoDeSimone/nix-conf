{ ... }: {
  imports = [ ./modules.nix ./style.nix ];
  programs.waybar = {
    enable = true;
    catppuccin.enable = false;

    settings = {
      mainBar = {
        position = "bottom";
        height = 10;

        modules-left = [
          "custom/menu"
          "custom/separator#dot-line"
          "group/motherboard"
          "custom/separator#blank"
          "group/laptop"
          "custom/separator#line"
          "custom/weather"
        ];

        modules-center = [
          "custom/swaync"
          "custom/cava_mviz"
          "custom/separator#dot-line"
          "clock"
          "custom/separator#line"
          "hyprland/workspaces#roman"
        ];

        modules-right = [
          "network#speed"
          "custom/separator#line"
          "tray"
          "mpris"
          "bluetooth"
          "group/audio"
          "keyboard-state"
          "custom/keyboard"
          "custom/lock"
          "custom/separator#dot-line"
          "custom/power"
        ];
      };
    };
  };
}
