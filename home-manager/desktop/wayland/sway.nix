{ pkgs
, lib
, config
, ...
}:
let
  master-layout =
    pkgs.writers.writePython3Bin "sway-master-layout"
      {
        libraries = [ pkgs.python3Packages.i3ipc ];
        flakeIgnore = [ "E302" "E305" "E501" "W391" "E261" "F841" "E701" ];
      } ''
      from i3ipc import Connection, Event
      def on_window_close(ipc, event):
          tree = ipc.get_tree()
          focused = tree.find_focused()
          if not focused: return
          ws = focused.workspace()
          if ws is None or ws.layout in ["tabbed", "stacked"]: return
          if len(ws.nodes) == 1 and ws.nodes[0].layout == "tabbed":
              commands = [
                  f"[con_id={focused.id}] move to workspace current",
                  f"[con_id={focused.id}] move left",
                  f"[con_id={focused.id}] layout toggle split"
                  f"[con_id={focused.id}] layout splith"
              ]
              ipc.command("; ".join(commands))
              ipc.command(f"[con_id={focused.id}] focus parent")
      def on_window_new(ipc, event):
          new_win_id = event.container.id
          tree = ipc.get_tree()
          new_win = tree.find_by_id(new_win_id)
          if not new_win or new_win.floating == "on": return
          ws = new_win.workspace()
          if ws is None: return
          if ws.layout in ["tabbed", "stacked"]: return
          target_tab = next(
              (n for n in ws.nodes if n.layout == "tabbed" and n.id != new_win.id), None
          )
          if target_tab:
              mark = "_autotile_target"
              commands = [
                  f'[con_id={target_tab.id}] mark --replace "{mark}"',
                  f'[con_id={new_win.id}] move window to mark "{mark}"',
                  f'[con_id={target_tab.id}] unmark "{mark}"',
                  f"[con_id={new_win.id}] focus",
              ]
              ipc.command("; ".join(commands))
          else:
              count = len(ws.nodes)
              if count == 1:
                  ipc.command(f"[con_id={new_win.id}] layout splith")
              elif count == 2:
                  ipc.command(
                      f"[con_id={new_win.id}] splitv; [con_id={new_win.id}] layout tabbed"
                  )
      def main():
          ipc = Connection()
          ipc.on(Event.WINDOW_NEW, on_window_new)
          ipc.on(Event.WINDOW_CLOSE, on_window_close)
          ipc.main()
      if __name__ == "__main__":
          main()
    '';

  focus-master =
    pkgs.writers.writePython3Bin "sway-focus-master"
      {
        libraries = [ pkgs.python3Packages.i3ipc ];
        flakeIgnore = [ "E302" "E305" "E501" "W391" "E701" ];
      } ''
      from i3ipc import Connection
      ipc = Connection()
      focused = ipc.get_tree().find_focused()
      if not focused: exit()
      ws = focused.workspace()
      if len(ws.nodes) < 2: exit()
      ipc.command(f"[con_id={ws.nodes[0].id}] focus")
    '';
  swap-master =
    pkgs.writers.writePython3Bin "sway-swap-master"
      {
        libraries = [ pkgs.python3Packages.i3ipc ];
        flakeIgnore = [ "E302" "E305" "E501" "W391" "E701" ];
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
in
{
  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
  };
  systemd.user.services = {
    sworkstyle = {
      Unit = {
        Description = "Swayest Workstyle Daemon";
        PartOf = [ "sway-session.target" ];
        After = [ "sway-session.target" ];
      };
      Install = { WantedBy = [ "sway-session.target" ]; };
      Service = {
        ExecStart = "${pkgs.swayest-workstyle}/bin/sworkstyle -d -l off";
        Restart = "always";
        RestartSec = "1s";
      };
    };
    sway-master-layout = {
      Unit = {
        Description = "Sway Master Layout Daemon";
        PartOf = [ "sway-session.target" ];
        After = [ "sway-session.target" ];
      };
      Install = {
        WantedBy = [ "sway-session.target" ];
      };
      Service = {
        ExecStart = "${master-layout}/bin/sway-master-layout";
        Restart = "always";
        RestartSec = "1s";
        Environment = "PYTHONUNBUFFERED=1";
      };
    };
  };

  xdg.configFile."sworkstyle/config.toml".text = ''
    fallback = ''
    separator = ' '
    [matching]
    'firefox' = ''
    'LibreWolf' = ''
    'Google-chrome' = ''
    'Chromium' = ''
    'Brave-browser' = ''
    'ayugram-desktop' = ''
    'TelegramDesktop' = ''
    'discord' = ''
    'WebCord' = ''
    'Vesktop' = ''
    'Slack' = ''
    'FreeTube' = '󰗃'
    'Spotify' = ''
    'supersonic' = ''
    'finamp' = ''
    'vlc' = ''
    'mpv' = ''
    'pavucontrol' = ''
    'obsidian' = ''
    'foot' = ''
    'Alacritty' = ''
    'kitty' = ''
    'nm-connection-editor' = ''
    'blueman-manager' = ''
    'thunar' = ''
    'org.gnome.Nautilus' = ''
    'dragon' = ''
    'transmission-gtk' = ''
    'swayimg' = ''
  '';
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraConfig = ''
      include ~/.config/sway/outputs
    '';
    config = {
      window.commands = [
        {
          criteria = { app_id = "pavucontrol"; };
          command = "floating enable, resize set 800 600, move position center";
        }
        {
          criteria = { class = "FreeTube"; };
          command = "fullscreen disable";
        }
        {
          criteria = { app_id = "nm-connection-editor"; };
          command = "floating enable";
        }
        {
          criteria = { title = "(?:Open|Save) (?:File|Folder|As)"; };
          command = "floating enable, resize set 800 600";
        }
      ];
      colors = {
        focused = {
          border = "$mauve";
          background = "$base";
          text = "$text";
          indicator = "$rosewater";
          childBorder = "$mauve";
        };
        focusedInactive = {
          border = "$overlay0";
          background = "$base";
          text = "$text";
          indicator = "$rosewater";
          childBorder = "$overlay0";
        };
        unfocused = {
          border = "$overlay0";
          background = "$base";
          text = "$text";
          indicator = "$rosewater";
          childBorder = "$overlay0";
        };
        urgent = {
          border = "$peach";
          background = "$base";
          text = "$peach";
          indicator = "$overlay0";
          childBorder = "$peach";
        };
        placeholder = {
          border = "$overlay0";
          background = "$base";
          text = "$text";
          indicator = "$overlay0";
          childBorder = "$overlay0";
        };
        background = "$base";
      };

      modifier = "Mod4";
      terminal = "${pkgs.foot}/bin/foot";
      menu = "${config.programs.rofi.package}/bin/rofi -show drun";
      bars = [
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
        { command = "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store"; }
        { command = "${pkgs.dunst}/bin/dunst"; }
        { command = "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"; }
        { command = "${pkgs.swaybg}/bin/swaybg -i /usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png"; }
        { command = "${pkgs.networkmanagerapplet}/bin/nm-applet"; }
      ];
      modes = {
        screenshot = {
          "p" = "exec ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy; mode default";
          "s" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy; mode default";
          "w" = "exec ${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '.. | select(.pid? and .visible?) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | ${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - | ${pkgs.wl-clipboard}/bin/wl-copy; mode default";
          "e" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.swappy}/bin/swappy -f -; mode default";
          "Escape" = "mode default";
          "Return" = "mode default";
        };
        resize = {
          "Down" = "resize grow height 10 px";
          "Escape" = "mode default";
          "Left" = "resize shrink width 10 px";
          "Return" = "mode default";
          "Right" = "resize grow width 10 px";
          "Up" = "resize shrink height 10 px";
          "h" = "resize shrink width 10 px";
          "j" = "resize grow height 10 px";
          "k" = "resize shrink height 10 px";
          "l" = "resize grow width 10 px";
        };
      };

      keybindings = lib.mkOptionDefault {
        # --- Plugins ---
        "Mod4+r" = "exec ${focus-master}/bin/sway-focus-master";
        "Mod4+Shift+r" = "exec ${swap-master}/bin/sway-swap-master";
        "Mod4+Alt_L+r" = "mode resize";
        "Mod4+Escape" = "exec ${config.programs.sway-easyfocus.package}/bin/sway-easyfocus";
        "Mod4+Tab" = "exec ${config.programs.swayr.package}/bin/swayr switch-window";

        # --- SwayOSD: Volume (Max 120%) ---
        "--release XF86AudioRaiseVolume" = "exec ${config.services.swayosd.package}/bin/swayosd-client --output-volume raise --max-volume 120";
        "--release XF86AudioLowerVolume" = "exec ${config.services.swayosd.package}/bin/swayosd-client --output-volume lower --max-volume 120";
        "--release XF86AudioMute" = "exec ${config.services.swayosd.package}/bin/swayosd-client --output-volume mute-toggle";
        "--release XF86AudioMicMute" = "exec ${config.services.swayosd.package}/bin/swayosd-client --input-volume mute-toggle";

        # --- SwayOSD: Brightness ---
        "--release XF86MonBrightnessUp" = "exec ${config.services.swayosd.package}/bin/swayosd-client --brightness raise";
        "--release XF86MonBrightnessDown" = "exec ${config.services.swayosd.package}/bin/swayosd-client --brightness lower";

        # --- SwayOSD: Caps Lock ---
        "--release Caps_Lock" = "exec ${config.services.swayosd.package}/bin/swayosd-client --caps-lock";

        # --- SwayOSD: Media Player Keys ---
        "XF86AudioPlay" = "exec ${config.services.swayosd.package}/bin/swayosd-client --playerctl play-pause";
        "XF86AudioNext" = "exec ${config.services.swayosd.package}/bin/swayosd-client --playerctl next";
        "XF86AudioPrev" = "exec ${config.services.swayosd.package}/bin/swayosd-client --playerctl previous";

        # --- Alternative Media Control  ---
        "Control+KP_End" = "exec ${config.services.swayosd.package}/bin/swayosd-client --playerctl previous";
        "Control+KP_Down" = "exec ${config.services.swayosd.package}/bin/swayosd-client --playerctl play-pause";
        "Control+KP_Next" = "exec ${config.services.swayosd.package}/bin/swayosd-client --playerctl next";

        # --- Applications ---
        "Mod4+Control+Shift+f" = "exec ${pkgs.foot}/bin/foot -- ${pkgs.yazi}/bin/yazi";
        "Control+Shift+Escape" = "exec ${pkgs.foot}/bin/foot -- ${pkgs.htop}/bin/htop";
        "Mod4+Return" = "exec ${pkgs.foot}/bin/foot";
        "Mod4+b" = "exec $HOME/.nix-profile/bin/firefox";

        # Rofi
        "Mod4+Control+Shift+d" = "exec ${pkgs.rofi-pass-wayland}/bin/rofi-pass";
        "Mod4+d" = "exec ${config.programs.rofi.package}/bin/rofi -show drun";

        # --- System Utils ---
        "Mod4+space" = "exec ${pkgs.dunst}/bin/dunstctl close-all";
        "Mod4+Shift+q" = "kill";
        "Mod4+Shift+c" = "reload";
        "Mod4+Shift+e" = "exec ${pkgs.wlogout}/bin/wlogout";

        # --- Clipboard & Screenshots ---
        "Mod4+Alt_L" = "exec ${pkgs.clipman}/bin/clipman pick --tool=CUSTOM --tool-args='${config.programs.rofi.package}/bin/rofi -dmenu -sorting-method fzf -sort -i'";
        "Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy";
        "Mod4+KP_Delete" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy";
        "Shift+Print" = "mode screenshot";
        "Mod4+Shift+KP_Delete" = "mode screenshot";

        # --- Window Management ---
        "Mod4+l" = "exec /usr/bin/swaylock -f";
        "Mod4+f" = "fullscreen toggle";
        "Mod4+Shift+space" = "floating toggle";
        "Mod4+w" = "layout toggle tabbed split";
        "Mod4+e" = "layout toggle split";
        "Mod4+h" = "exec splith";
        "Mod4+v" = "exec splitv";
      };
    };
    systemd.enable = true;
  };

  programs.sway-easyfocus = {
    enable = true;
    settings = {
      chars = "tgbnvuir";
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

      format = {
        icon_dirs = [
          "/run/current-system/sw/share/icons/hicolor"
          "${pkgs.adwaita-icon-theme}/share/icons/Adwaita"
        ];
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
