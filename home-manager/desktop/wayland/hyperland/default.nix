{ pkgs, ... }:
let
  catppuccinDrv = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/catppuccin/hyprland/main/themes/mocha.conf";
    hash = "sha256-SxVNvZZjfuPA2yB9xA0EHHEnE9eIQJAFVBIUuDiSIxQ=";
  };
  keybinds = builtins.readFile ./config/keybinds.conf;
  exec = builtins.readFile ./config/exec.conf;
  vars = builtins.readFile ./config/vars.conf;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      misc = { force_default_wallpaper = 1; };

      master = {
        new_is_master = false;
        orientation = "left";
      };

      input = {
        kb_layout = "us";
        follow_mouse = 2;
        repeat_rate = 50;
        repeat_delay = 300;
        touchpad = { natural_scroll = true; };
        sensitivity = 0;
      };
      animations = { enabled = false; };
      general = {
        gaps_in = 1;
        gaps_out = 1;
        border_size = 2;
        layout = "master";
        allow_tearing = false;
      };
      workspace = [
        "1,monitor:HDMI-A-1"
        "2,monitor:HDMI-A-1"
        "3,monitor:HDMI-A-1"
        "4,monitor:HDMI-A-1"
        "5,monitor:HDMI-A-1"
        "6,monitor:eDP-1"
        "7,monitor:eDP-1"
        "8,monitor:eDP-1"
        "9,monitor:eDP-1"
        "0,monitor:eDP-1"
      ];
      monitor = [ "eDP-1, 1920x1200, 1920x0, 1" "HDMI-A-1, 1920x1080, 0x0, 1" ];
    };
    extraConfig = ''
      # Example windowrule v1
      # windowrule = float, ^(kitty)$
      # Example windowrule v2
      # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
      windowrulev2 = suppressevent maximize, class:.* # You'll probably like this.

      source=${catppuccinDrv}
      ${vars}
      ${exec}
      ${keybinds}
    '';
  };
}
