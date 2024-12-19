{
  programs.waybar.settings.mainBar = {
    "layer" = "bottom";
    "position" = "bottom";
    "height" = 15;

    "modules-left" = ["hyprland/workspaces"];
    "modules-center" = [];
    "modules-right" = [
      "custom/playerctl"
      "custom/separator#line"
      "network#speed"
      "custom/separator#line"
      "cpu"
      "memory"
      "disk"
      "temperature"
      "backlight"
      "custom/separator#line"
      "pulseaudio"
      "battery"
      "custom/separator#line"
      "clock"
      "custom/separator#line"
      "tray"
    ];

    "hyprland/workspaces" = {};
    "tray" = {
      "icon-size" = 18;
      "spacing" = 15;
    };

    "clock" = {
      "format" = "{:%a %b %e  %R}";
      "interval" = 30;
    };

    "cpu" = {
      "interval" = 1;
      "format" = "  {icon0}{icon1}{icon2}{icon3} {usage:>2}% ";
      "format-icons" = ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"];
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
      "format-icons" = ["" "" "" "" ""];
      "interval" = 30;
    };

    "custom/separator#line" = {
      "format" = "|";
      "interval" = "once";
      "tooltip" = false;
    };

    "custom/playerctl" = {
      "format" = "<span>{}</span>";
      "return-type" = "json";
      "max-length" = 30;
      "min-length" = 30;
      "exec" = ''
        $HOME/.nix-profile/bin/playerctl -a metadata --format '{"text": "{{artist}} ~ {{markup_escape(title)}}", "tooltip": "{{playerName}} : {{markup_escape(title)}}", "alt": "{{status}}", "class": "{{status}}"}' -F'';
      "on-click-middle" = "playerctl play-pause";
      "on-click" = "playerctl previous";
      "on-click-right" = "playerctl next";
      "scroll-step" = 5.0;
      "smooth-scrolling-threshold" = 1;
    };

    "memory" = {
      "interval" = 30;
      "format" = "  {used:0.1f}G/{total:0.1f}G ";
    };

    "disk" = {
      "format" = "  {percentage_used}% ";
      "interval" = 30;
    };

    "temperature" = {
      "thermal-zone" = 0;
      "format" = " {icon} {temperatureC}°C ";
      "format-icons" = [""];
      "interval" = 30;
    };

    "network#speed" = {
      "interval" = 1;
      "format" = "{ifname}";
      "format-wifi" = " {bandwidthUpBytes}  {bandwidthDownBytes}";
      "format-ethernet" = " {bandwidthUpBytes}  {bandwidthDownBytes}";
      "format-disconnected" = "󰌙";
      "tooltip-format" = "{ipaddr}";
      "format-linked" = "󰈁 {ifname} (No IP)";
      "tooltip-format-wifi" = "{essid} {icon} {signalStrength}%";
      "tooltip-format-ethernet" = "{ifname} 󰌘";
      "tooltip-format-disconnected" = "󰌙 Disconnected";
      "max-length" = 24;
      "min-length" = 24;
    };

    "backlight" = {
      "device" = "intel_backlight";
      "format" = " 󱍖 {percent}% ";
      "interval" = 60;
    };

    "pulseaudio" = {
      "format" = "{icon}  {volume}%  ";
      "format-bluetooth" = "   {volume}% ";
      "format-muted" = "Mute";
      "interval" = 60;

      "format-icons" = {"default" = [""];};

      "on-click" = "blueman-manager";
    };
  };
}
