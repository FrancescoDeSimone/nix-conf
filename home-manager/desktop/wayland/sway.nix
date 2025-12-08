{
  pkgs,
  lib,
  config,
  ...
}: let
  master-layout =
    pkgs.writers.writePython3Bin "sway-master-layout" {
      libraries = [pkgs.python3Packages.i3ipc];
      flakeIgnore = ["E302" "E305" "E501" "W391" "E261" "F841"];
    } ''
      from i3ipc import Connection, Event
      def on_window_new(ipc, event):
          try:
              focused = ipc.get_tree().find_focused()
              ws = focused.workspace()
          except AttributeError:
              return
          nodes = [n for n in ws.nodes if n.type == "con"]
          if len(nodes) == 1:
              ipc.command(f"[con_id={nodes[0].id}] layout splith")
              return
          if len(nodes) == 2:
              stack_window = nodes[1]
              if stack_window.layout == "tabbed":
                  return
              ipc.command(f"[con_id={stack_window.id}] splitv")
              ipc.command(f"[con_id={stack_window.id}] layout tabbed")
              ipc.command(f"[con_id={stack_window.id}] focus")
          else:
              return
      def main():
          ipc = Connection()
          ipc.on(Event.WINDOW_NEW, on_window_new)
          ipc.main()
      if __name__ == "__main__":
          main()
    '';

  swap-master =
    pkgs.writers.writePython3Bin "sway-swap-master" {
      libraries = [pkgs.python3Packages.i3ipc];
      flakeIgnore = ["E302" "E305" "E501" "W391" "E701"];
    } ''
      from i3ipc import Connection
      ipc = Connection()
      focused = ipc.get_tree().find_focused()
      if not focused: exit()
      ws = focused.workspace()
      if len(ws.nodes) < 2: exit()
      master = ws.nodes[0]
      target = ws.nodes[1] if focused.id == master.id else master
      ipc.command(f"[con_id={focused.id}] swap container with con_id {target.id}")
      ipc.command(f"[con_id={ws.nodes[0].id}] focus")
    '';
in {
  systemd.user.services.sway-master-layout = {
    Unit = {
      Description = "Sway Master Layout Daemon";
      PartOf = ["sway-session.target"];
      After = ["sway-session.target"];
    };
    Install = {
      WantedBy = ["sway-session.target"];
    };
    Service = {
      ExecStart = "${master-layout}/bin/sway-master-layout";
      Restart = "always";
      RestartSec = "1s";
      Environment = "PYTHONUNBUFFERED=1";
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    wrapperFeatures.gtk = true;
    extraConfig = ''
      include ~/.config/sway/outputs
    '';
    config = {
      modifier = "Mod4";
      terminal = "${pkgs.foot}/bin/foot";
      menu = "${config.programs.rofi.package}/bin/rofi -show drun";
      bars = [
        {command = "${pkgs.waybar}/bin/waybar";}
      ];
      input = {
        "type:touchpad" = {
          dwt = "enabled";
          tap = "enabled";
          natural_scroll = "enabled";
          middle_emulation = "enabled";
        };
        "9639:64097:Compx_2.4G_Receiver_Mouse" = {
          scroll_method = "on_button_down";
          scroll_button = "274";
          repeat_delay = "100";
          repeat_rate = "50";
          accel_profile = "flat";
          pointer_accel = "0";
        };
        "type:keyboard" = {
          xkb_layout = "us";
          repeat_delay = "200";
          repeat_rate = "50";
        };
      };
      gaps = {
        inner = 0;
        outer = 0;
      };
      window = {
        border = 2;
        titlebar = false;
      };
      startup = [
        {command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway";}
        {command = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP";}

        {command = "systemctl --user stop xdg-desktop-portal xdg-desktop-portal-wlr";}
        {command = "systemctl --user start xdg-desktop-portal xdg-desktop-portal-wlr";}
        {
          command = "${config.programs.swayr.package}/bin/swayrd";
          always = true;
        }
        {command = "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store";}
        {command = "swayosd-server";}
        {command = "${pkgs.dunst}/bin/dunst";}
        {command = "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1";}
        {command = "${pkgs.swaybg}/bin/swaybg -i /usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png";}
        {command = "${pkgs.networkmanagerapplet}/bin/nm-applet";}
      ];

      keybindings = lib.mkOptionDefault {
        "Mod4+r" = "exec ${swap-master}/bin/sway-swap-master";
        # --- Plugins (Now using absolute paths) ---
        "Mod4+Escape" = "exec ${config.programs.sway-easyfocus.package}/bin/sway-easyfocus";
        "Mod4+Tab" = "exec ${config.programs.swayr.package}/bin/swayr switch-window";

        # --- SwayOSD (Volume/Brightness/Caps) ---
        "--release XF86AudioRaiseVolume" = "exec ${config.services.swayosd.package}/bin/swayosd-client --output-volume raise";
        "--release XF86AudioLowerVolume" = "exec ${config.services.swayosd.package}/bin/swayosd-client --output-volume lower";
        "--release XF86AudioMute" = "exec ${config.services.swayosd.package}/bin/swayosd-client --output-volume mute-toggle";
        "--release XF86MonBrightnessUp" = "exec ${config.services.swayosd.package}/bin/swayosd-client --brightness raise";
        "--release XF86MonBrightnessDown" = "exec ${config.services.swayosd.package}/bin/swayosd-client --brightness lower";
        "--release Caps_Lock" = "exec ${config.services.swayosd.package}/bin/swayosd-client --caps-lock";

        # --- Applications ---
        "Mod4+Control+Shift+f" = "exec ${pkgs.foot}/bin/foot -- ${pkgs.yazi}/bin/yazi";
        "Control+Shift+Escape" = "exec ${pkgs.foot}/bin/foot -- ${pkgs.htop}/bin/htop";
        "Mod4+Return" = "exec ${pkgs.foot}/bin/foot";
        "Mod4+b" = "exec $HOME/.nix-profile/bin/firefox";
        # Note: rofi-pass-wayland package provides 'rofi-pass' binary
        "Mod4+Control+Shift+d" = "exec ${pkgs.rofi-pass-wayland}/bin/rofi-pass";
        "Mod4+d" = "exec ${config.programs.rofi.package}/bin/rofi -show drun";

        # --- System Utils ---
        "Mod4+space" = "exec ${pkgs.dunst}/bin/dunstctl close-all";
        "Mod4+Shift+q" = "kill";
        "Mod4+Shift+c" = "reload";
        # Note: swaynag comes with sway, so we usually assume it's in path, but if sway is system-installed, this is fine.
        "Mod4+Shift+e" = "exec ${pkgs.wlogout}/bin/wlogout";

        # --- Media Control ---
        "Control+KP_End" = "exec ${pkgs.playerctl}/bin/playerctl previous";
        "Control+KP_Down" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
        "Control+KP_Next" = "exec ${pkgs.playerctl}/bin/playerctl next";

        # --- Clipboard & Screenshots ---
        "Mod4+Alt_L" = "exec ${pkgs.clipman}/bin/clipman pick --tool=CUSTOM --tool-args='${config.programs.rofi.package}/bin/rofi -dmenu -sorting-method fzf -sort -i'";
        "Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy";

        # --- Window Management ---
        "Mod4+f" = "fullscreen toggle";
        "Mod4+Shift+space" = "floating toggle";
        "Mod4+w" = "layout toggle tabbed split";
        "Mod4+e" = "layout toggle split";
        "Mod4+l" = "exec /usr/bin/swaylock -f";
      };
    };
    systemd.enable = true;
  };

  # programs.sway-easyfocus = {enable = true;};
  programs.sway-easyfocus = {
    enable = true;
    settings = {
      chars = "tgbnvuir"; # Home row keys for easy reach
      fill_color = "1e1e2e";
      label_color = "cdd6f4";
      border_color = "89b4fa";
      text_color = "1e1e2e";
    };
  };
  programs.swayr = {
    enable = true;
    systemd.enable = true;

    settings = {
      menu = {
        executable = "${config.programs.rofi.package}/bin/rofi";
        args = [
          "-dmenu"
          "-i" # Case insensitive search
          "-markup-rows" # Allows swayr to bold/color text
          "-p" # Flag for the prompt
          "{prompt}" # Placeholder that swayr replaces (e.g. "Switch Window")
        ];
      };

      # (Optional) Clean up the format to reduce "No icon" warnings in logs
      format = {
        icon_dirs = [
          "/run/current-system/sw/share/icons/hicolor"
          "${pkgs.adwaita-icon-theme}/share/icons/Adwaita"
        ];
        # Fallback format if icons are missing
        window_format = "{app_name} - {title} ({workspace_name})";
      };
    };
  };
  programs.swaylock = {
    enable = true;
    settings = {
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      show-failed-attempts = true;
    };
  };
  services.swayosd.enable = true;

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 900;
        command = "/usr/bin/swaylock -f";
      }
      {
        timeout = 1200;
        command = "swaymsg \"output * dpms off\"";
        resumeCommand = "swaymsg \"output * dpms on\"";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "/usr/bin/swaylock -f";
      }
    ];
  };
}
