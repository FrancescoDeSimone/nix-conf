{
  pkgs,
  lib,
  config,
  ...
}: let
  pomodoro = pkgs.rustPlatform.buildRustPackage {
    pname = "waybar-module-pomodoro";
    version = "master";

    src = pkgs.fetchFromGitHub {
      owner = "Andeskjerf";
      repo = "waybar-module-pomodoro";
      rev = "master";
      hash = "sha256-vB5WROn/GmaJyLNHnyfhTZItjQlJ+LMXMw8gOT1GM0s=";
    };
    cargoHash = "sha256-FTzqNkGn1dk+pdee8U07NI/uqUR6/gs51ZWOpYro3j8=";
    doCheck = false;
  };
in {
  home.packages = [pomodoro];

  programs.waybar.settings.mainBar = {
    "layer" = "bottom";
    "position" = "bottom";
    "height" = 15;

    "modules-left" = [
      "sway/workspaces"
      "sway/mode"
      "hyprland/workspaces"
    ];
    "modules-center" = [];
    "modules-right" = [
      # "custom/playerctl"
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
      "bluetooth"
      "battery"
      "custom/separator#line"
      "custom/pomodoro"
      "clock"
      "custom/separator#line"
      "custom/dunst"
      "custom/separator#line"
      "custom/wotw"
      "custom/separator#line"
      "tray"
    ];

    "sway/workspaces" = {
      "disable-scroll" = true;
      "all-outputs" = false;
      "format" = "{icon}";
    };
    "sway/mode" = {
      "format" = "<span style=\"italic\">{}</span>";
    };

    "hyprland/workspaces" = {};
    "tray" = {
      "icon-size" = 18;
      "spacing" = 15;
    };

    "clock" = {
      "format" = "{:%a %b %e  %R}";
      "interval" = 30;
      "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
    };

    "custom/pomodoro" = {
      "format" = "{}";
      "return-type" = "json";
      "exec" = "${pomodoro}/bin/waybar-module-pomodoro";
      "on-click" = "${pomodoro}/bin/waybar-module-pomodoro toggle";
      "on-click-right" = "${pomodoro}/bin/waybar-module-pomodoro reset";
      "tooltip" = true;
    };
    "cpu" = {
      "interval" = 1;
      "format" = "  {icon0}{icon1}{icon2}{icon3} {usage:>2}% ";
      "format-icons" = ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"];
      "tooltip" = true;
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
      "tooltip-format" = "{timeTo}\nPower: {power}W\nHealth: {health}%";
    };

    "custom/separator#line" = {
      "format" = "|";
      "interval" = "once";
      "tooltip" = false;
    };
    "custom/dunst" = {
      "return-type" = "json";
      "exec" = pkgs.writeShellScript "dunst-status" ''
        COUNT=$(${pkgs.dunst}/bin/dunstctl count waiting)
        ENABLED=""
        DISABLED=""
        if ${pkgs.dunst}/bin/dunstctl is-paused | grep -q "true"; then
          printf '{"text": "%s", "tooltip": "Dunst is Paused", "class": "paused"}\n' "$DISABLED"
        else
          printf '{"text": "%s", "tooltip": "Dunst is Active", "class": "active"}\n' "$ENABLED"
        fi
      '';
      "on-click" = "${pkgs.dunst}/bin/dunstctl set-paused toggle; ${pkgs.procps}/bin/pkill -RTMIN+8 waybar";
      "signal" = 8;
      "restart-interval" = 2;
    };

    "custom/wotw" = {
      "return-type" = "json";
      "exec" = pkgs.writeShellScript "wotw" ''
        #!/usr/bin/env bash
        # 1. Fetch the line
        ARTICLE_LINE=$(${pkgs.curl}/bin/curl -s https://greensdictofslang.com/ | ${pkgs.gnugrep}/bin/grep -oP '<article class="srentry">.*</span>')
        WORD=$(echo "$ARTICLE_LINE" | ${pkgs.gnugrep}/bin/grep -oP '<span class="hw">\K[^<]+' | ${pkgs.gnused}/bin/sed 's/,$//' | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        DEFS_RAW=$(echo "$ARTICLE_LINE" | ${pkgs.gnugrep}/bin/grep -oP '<span class="srhead">.*?</span>\K.*')
        DEFS_LINES=$(echo "$DEFS_RAW" | \
          ${pkgs.gnused}/bin/sed 's|<span class="srdefinition">|\n&|g' | \
          ${pkgs.coreutils-full}/bin/tail -n +2 | \
          ${pkgs.gnused}/bin/sed -E '
            s|<span class="senseno">[^<]+</span>||g;
            s|<[^>]+>||g;
            s/&nbsp;/ /g;
            s/\[[^]]+\]//g;
            s/\s+/ /g;
            s/^\s+|\s+$//g;
            s/\s\././g;
          ' | \
          ${pkgs.gnugrep}/bin/grep .
        )
        FINAL_DEFS=$(echo "$DEFS_LINES" | ${pkgs.coreutils-full}/bin/paste -sd '; ' -)
        printf '{"text": "%s", "tooltip": "%s"}\n' "$WORD" "$FINAL_DEFS"
      '';
      "interval" = "once";
      "tooltip" = true;
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
      "tooltip-format" = "RAM: {used:0.1f}GiB / {total:0.1f}GiB ({percentage}%)\nSwap: {swapUsed:0.1f}GiB / {swapTotal:0.1f}GiB ({swapPercentage}%)";
    };

    "disk" = {
      "format" = "  {percentage_used}% ";
      "interval" = 30;
      "tooltip-format" = "{path}: {used} used / {total} total ({percentage_used}%)";
    };

    "temperature" = {
      "thermal-zone" = 0;
      "format" = " {icon} {temperatureC}°C ";
      "format-icons" = [""];
      "interval" = 30;
      "tooltip-format" = "Thermal Zone: {thermal_zone}\nCritical: {critical}°C";
    };

    "network#speed" = {
      "interval" = 1;
      "format" = "{ifname}";
      "format-wifi" = " {bandwidthUpBytes}  {bandwidthDownBytes}";
      "format-ethernet" = " {bandwidthUpBytes}  {bandwidthDownBytes}";
      "format-disconnected" = "󰌙";
      "tooltip-format" = "{ipaddr}";
      "format-linked" = "󰈁 {ifname} (No IP)";
      "max-length" = 24;
      "min-length" = 24;
      "tooltip-format-wifi" = "{essid} ({frequency}GHz) {icon} {signalStrength}%\nIP: {ipaddr}";
      "tooltip-format-ethernet" = "{ifname} 󰌘\nIP: {ipaddr}";
      "tooltip-format-disconnected" = "󰌙 Disconnected";
    };

    "backlight" = {
      "device" = "intel_backlight";
      "format" = " 󱍖 {percent}% ";
      "interval" = 60;
      "tooltip-format" = "Backlight: {percent}%";
    };
    "bluetooth" = {
      format-connected-battery = " {device_battery_percentage}% ";
      format-connected = " ";
      format-on = " On ";
      format-off = " Off ";
      on-click = "${pkgs.blueman}/bin/blueman-manager";
      "tooltip-format-connected" = "Connected:\n{device_enumerate}";
      "tooltip-format-enumerate-connected" = "{device_alias}";
      "tooltip-format-enumerate-connected-battery" = "{device_alias} ({device_battery_percentage}%)";
    };

    "pulseaudio" = {
      "format" = "{icon}  {volume}%  ";
      "format-bluetooth" = "   {volume}% ";
      "format-muted" = "Mute";
      "interval" = 60;
      "format-icons" = {"default" = [""];};
      "on-click" = "${pkgs.pavucontrol}/bin/pavucontrol";
      "tooltip-format" = "{desc} ({volume}%)";
    };
  };
}
