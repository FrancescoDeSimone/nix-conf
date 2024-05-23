{
  programs.waybar.settings.mainBar = {
    "layer" = "bottom";
    "position" = "bottom";
    "height" = 15;

    "modules-left" = [ "hyprland/workspaces" ];
    "modules-center" = [ ];
    "modules-right" =
      [ "temperature" "backlight" "pulseaudio" "battery" "clock" "tray" ];

    "hyprland/workspaces" = { };
    "tray" = {
      "icon-size" = 18;
      "spacing" = 15;
    };

    "clock" = {
      "format" = "{:%a %b %e  %R}";
      "interval" = 30;
    };

    "battery" = {
      "bat" = "BAT0";
      "states" = {
        "full" = 99;
        "good" = 98;
        "normal" = 98;
        "warning" = 20;
        "critical" = 20;
      };

      "format" = "{icon}   {capacity}%";
      "format-good" = "{icon}   {capacity}%";
      "format-full" = "   {capacity}%";
      "format-icons" = [ "" "" "" "" "" ];
      "interval" = 30;
    };

    "temperature" = {
      "thermal-zone" = 0;
      "format" = "{icon} {temperatureC}°C";
      "format-icons" = [ "" ];
      "interval" = 30;
    };

    "backlight" = {
      "device" = "intel_backlight";
      "format" = "{icon}  {percent}%  ";
      "interval" = 60;
    };

    "pulseaudio" = {
      "format" = "{icon}  {volume}%  ";
      "format-bluetooth" = "  {volume}%  ";
      "format-muted" = "Mute";
      "interval" = 60;

      "format-icons" = { "default" = [ "" ]; };

      "on-click" = "blueman-manager";

    };

  };
}
