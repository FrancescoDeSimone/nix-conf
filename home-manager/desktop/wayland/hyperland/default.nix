{...}: let
  keybinds = builtins.readFile ./config/keybinds.conf;
  exec = builtins.readFile ./config/exec.conf;
  vars = builtins.readFile ./config/vars.conf;
  hyprlock = builtins.readFile ./config/hyprlock.conf;
in {
  services = {
    hypridle = {
      enable = true;
      settings = {
        general = {
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "hyprlock";
        };
        listener = [
          {
            timeout = 900;
            on-timeout = "hyprlock";
          }
          {
            timeout = 1200;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
  };
  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      ${hyprlock}
    '';
  };
  wayland.windowManager.hyprland = {
    catppuccin.enable = true;
    enable = true;
    settings = {
      misc = {force_default_wallpaper = 1;};

      master = {
        new_is_master = false;
        orientation = "left";
        allow_small_split = true;
        mfact = "0.50";
        no_gaps_when_only = 1;
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        repeat_rate = 50;
        repeat_delay = 200;
        scroll_factor = 2;
        touchpad = {natural_scroll = true;};
        sensitivity = 0;
      };
      animations = {enabled = false;};
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
        "6,monitor:HDMI-A-1"
        "7,monitor:HDMI-A-1"
        "8,monitor:HDMI-A-1"
        "9,monitor:HDMI-A-1"
        "0,monitor:eDP-1"
      ];
    };
    extraConfig = ''
      # Example windowrule v1
      # windowrule = float, ^(kitty)$
      # Example windowrule v2
      # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
      windowrulev2 = suppressevent maximize, class:.* # You'll probably like this.
      source = ~/.config/hypr/monitors.conf

      ${vars}
      ${exec}
      ${keybinds}
    '';
  };
}
