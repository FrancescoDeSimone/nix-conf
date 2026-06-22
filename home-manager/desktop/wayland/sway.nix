{
  pkgs,
  lib,
  config,
  ...
}: let
  swaylockCmd =
    if config.programs.swaylock.package != null
    then "${config.programs.swaylock.package}/bin/swaylock"
    else "/usr/bin/swaylock";
  master-layout =
    pkgs.writers.writePython3Bin "sway-master-layout"
    {
      libraries = [pkgs.python3Packages.i3ipc];
      flakeIgnore = ["E302" "E305" "E501" "W391" "E261" "F841" "E701" "E301" "E306" "E741"];
    } ''
      import asyncio
      from i3ipc.aio import Connection
      from i3ipc import Event
      STACK_LAYOUTS = ("tabbed", "stacked")
      MAINTAIN_DELAY = 0.03
      class SwayLayoutManager:
          def __init__(self):
              self.ipc = None
              self.lock = asyncio.Lock()
              self.maintain_task = None
              self.event_hint = None
          async def start(self):
              self.ipc = await Connection(auto_reconnect=True).connect()
              self.ipc.on(Event.WINDOW_NEW, self.on_window_new)
              self.ipc.on(Event.WINDOW_CLOSE, self.on_event)
              self.ipc.on(Event.WINDOW_MOVE, self.on_event)
              self.ipc.on(Event.WORKSPACE_FOCUS, self.on_event)
              await self.ipc.main()
          def trigger_maintain(self, hint=None):
              if hint:
                  self.event_hint = hint
              if self.maintain_task and not self.maintain_task.done():
                  self.maintain_task.cancel()
              async def delayed_maintain():
                  try:
                      await asyncio.sleep(MAINTAIN_DELAY)
                      async with self.lock:
                          await self.maintain_layout()
                  except asyncio.CancelledError:
                      pass
              self.maintain_task = asyncio.create_task(delayed_maintain())
          def is_floating(self, container):
              return container and container.floating and "on" in container.floating
          async def on_window_new(self, ipc, event):
              container = getattr(event, "container", None)
              if not container or self.is_floating(container):
                  return
              self.trigger_maintain(hint="new")
          async def on_event(self, ipc, event):
              container = getattr(event, "container", None)
              if container and self.is_floating(container):
                  return
              self.trigger_maintain()
          async def maintain_layout(self):
              try:
                  tree = await self.ipc.get_tree()
                  focused = tree.find_focused()
                  if not focused:
                      return
                  ws = focused.workspace()
                  if not ws or ws.name.startswith("__"):
                      return
                  if ws.layout in STACK_LAYOUTS:
                      await self.ipc.command("layout splith")
                      return
                  nodes = [n for n in ws.nodes if not (n.floating and "on" in n.floating)]
                  if not nodes:
                      return
                  all_leaves = [l for l in ws.leaves() if not (l.floating and "on" in l.floating)]
                  total_windows = len(all_leaves)
                  if total_windows == 0: return
                  if total_windows == 1:
                      leaf = all_leaves[0]
                      if len(nodes) == 1 and nodes[0].id != leaf.id:
                          await self.ipc.command(f"[con_id={leaf.id}] focus; move left; [con_id={focused.id}] focus")
                      return
                  stack = next((n for n in nodes if n.layout in STACK_LAYOUTS), None)
                  if len(nodes) == 1:
                      leaf_to_pop = all_leaves[1] if (all_leaves[0].focused and len(all_leaves) > 1) else all_leaves[0]
                      await self.ipc.command(
                          f"[con_id={nodes[0].id}] layout splith; [con_id={leaf_to_pop.id}] focus; move left; [con_id={focused.id}] focus"
                      )
                      return
                  loose_nodes = [n for n in nodes if n.id != (stack.id if stack else None)]
                  focused_loose = None
                  curr = focused
                  loose_ids = {n.id for n in loose_nodes}
                  while curr:
                      if curr.id in loose_ids:
                          focused_loose = curr
                          break
                      curr = curr.parent
                  if self.event_hint == "new":
                      master_node = next((n for n in loose_nodes if n.id != (focused_loose.id if focused_loose else None)), loose_nodes[0])
                  else:
                      master_node = focused_loose if focused_loose else loose_nodes[0]
                  commands = []
                  if not stack:
                      stack_target = next((n for n in loose_nodes if n.id != master_node.id), None)
                      if stack_target:
                          if nodes[0].id == stack_target.id:
                              commands.append(f"[con_id={master_node.id}] swap container with con_id {stack_target.id}")
                          commands.append(f"[con_id={stack_target.id}] focus; splitv; layout tabbed")
                          if len(loose_nodes) > 2:
                              commands.append(f'[con_id={stack_target.id}] mark --replace "_stack_init"')
                              for loose_node in loose_nodes:
                                  if loose_node.id != master_node.id and loose_node.id != stack_target.id:
                                      commands.append(f'[con_id={loose_node.id}] move window to mark "_stack_init"')
                              commands.append(f'[con_id={stack_target.id}] unmark "_stack_init"')
                  else:
                      if stack.layout not in STACK_LAYOUTS:
                          commands.append(f"[con_id={stack.id}] layout tabbed")
                      has_moves = False
                      for n in loose_nodes:
                          if n.id != master_node.id:
                              if not has_moves:
                                  commands.append(f'[con_id={stack.id}] mark --replace "_stack_sweep"')
                                  has_moves = True
                              commands.append(f'[con_id={n.id}] move window to mark "_stack_sweep"')
                      if has_moves:
                          commands.append(f'[con_id={stack.id}] unmark "_stack_sweep"')
                  if stack and ws.nodes and len(ws.nodes) > 0 and ws.nodes[0].id == stack.id:
                      commands.append(f"[con_id={stack.id}] swap container with con_id {master_node.id}")
                  if commands:
                      commands.append(f"[con_id={focused.id}] focus")
                      await self.ipc.command("; ".join(commands))
              except Exception:
                  pass
              finally:
                  self.event_hint = None
      if __name__ == "__main__":
          manager = SwayLayoutManager()
          asyncio.run(manager.start())
    '';
  focus-master =
    pkgs.writers.writePython3Bin "sway-focus-master"
    {
      libraries = [pkgs.python3Packages.i3ipc];
      flakeIgnore = ["E302" "E305" "E501" "W391" "E701"];
    } ''
      import sys
      from i3ipc import Connection
      def get_active_leaf(node):
          if not node.nodes:
              return node
          if node.focus:
              child = next((n for n in node.nodes if n.id == node.focus[0]), None)
              if child:
                  return get_active_leaf(child)
          return node
      ipc = Connection()
      tree = ipc.get_tree()
      focused = tree.find_focused()
      if not focused: sys.exit(0)
      ws = focused.workspace()
      if not ws or len(ws.nodes) < 1: sys.exit(0)
      master_leaf = get_active_leaf(ws.nodes[0])
      ipc.command(f"[con_id={master_leaf.id}] focus")
    '';

  swap-master =
    pkgs.writers.writePython3Bin "sway-swap-master"
    {
      libraries = [pkgs.python3Packages.i3ipc];
      flakeIgnore = ["E302" "E305" "E501" "W391" "E701"];
    } ''
      import sys
      from i3ipc import Connection
      def get_active_leaf(node):
          if not node.nodes:
              return node
          if node.focus:
              child = next((n for n in node.nodes if n.id == node.focus[0]), None)
              if child:
                  return get_active_leaf(child)
          return node
      def is_descendant_of(node, ancestor):
          current = node
          while current:
              if current.id == ancestor.id:
                  return True
              current = current.parent
          return False
      ipc = Connection()
      tree = ipc.get_tree()
      focused = tree.find_focused()
      if not focused: sys.exit(0)
      ws = focused.workspace()
      if not ws or len(ws.nodes) < 2: sys.exit(0)
      master_node = ws.nodes[0]
      stack_node = ws.nodes[1]
      master_leaf = get_active_leaf(master_node)
      stack_leaf = get_active_leaf(stack_node)
      is_master_focused = is_descendant_of(focused, master_node)
      if is_master_focused:
          ipc.command(f"[con_id={master_leaf.id}] swap container with con_id {stack_leaf.id}")
          ipc.command(f"[con_id={stack_leaf.id}] focus")
      else:
          ipc.command(f"[con_id={focused.id}] swap container with con_id {master_leaf.id}")
          ipc.command(f"[con_id={focused.id}] focus")
    '';
in {
  options.modules.desktop.sway = {
    wallpaper = lib.mkOption {
      type = lib.types.either lib.types.path lib.types.str;
      default = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
      description = "Path to the wallpaper image used by Sway";
    };
  };

  config = {
    catppuccin = {
      enable = true;
      flavor = "mocha";
      accent = "mauve";
      swaylock.enable = true;
    };

    systemd.user.services = {
      sway-audio-idle-inhibit = {
        Unit = {
          Description = "Sway Audio Idle Inhibit Daemon";
          PartOf = ["sway-session.target"];
          After = ["sway-session.target"];
        };
        Install = {WantedBy = ["sway-session.target"];};
        Service = {
          ExecStart = "${pkgs.unstable.sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit";
          Restart = "always";
          RestartSec = "1s";
        };
      };
      sworkstyle = {
        Unit = {
          Description = "Swayest Workstyle Daemon";
          PartOf = ["sway-session.target"];
          After = ["sway-session.target"];
        };
        Install = {WantedBy = ["sway-session.target"];};
        Service = {
          ExecStart = "${pkgs.swayest-workstyle}/bin/sworkstyle -d -l off";
          Restart = "always";
          RestartSec = "1s";
        };
      };
      sway-master-layout = {
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
        output = {
          "*" = {
            bg = "${config.modules.desktop.sway.wallpaper} fill";
          };
        };

        window.commands = [
          {
            criteria = {app_id = "blueman-manager";};
            command = "floating enable, resize set 800 600, move position center";
          }
          {
            criteria = {app_id = "pavucontrol";};
            command = "floating enable, resize set 800 600, move position center";
          }
          {
            criteria = {class = "FreeTube";};
            command = "fullscreen disable";
          }
          {
            criteria = {app_id = "nm-connection-editor";};
            command = "floating enable";
          }
          {
            criteria = {title = "(?:Open|Save) (?:File|Folder|As)";};
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
        bars = [];
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
          {command = "${pkgs.dunst}/bin/dunst";}
          {command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";}
          {command = "${pkgs.networkmanagerapplet}/bin/nm-applet";}
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
          "Mod4+r" = "exec ${focus-master}/bin/sway-focus-master";
          "Mod4+Shift+r" = "exec ${swap-master}/bin/sway-swap-master";
          "Mod4+Alt_L+r" = "mode resize";
          "Mod4+Escape" = "exec ${config.programs.sway-easyfocus.package}/bin/sway-easyfocus";
          "Mod4+Tab" = "exec ${config.programs.swayr.package}/bin/swayr switch-window";
          "--release XF86AudioRaiseVolume" = "exec ${config.services.swayosd.package}/bin/swayosd-client --output-volume raise --max-volume 120";
          "--release XF86AudioLowerVolume" = "exec ${config.services.swayosd.package}/bin/swayosd-client --output-volume lower --max-volume 120";
          "--release XF86AudioMute" = "exec ${config.services.swayosd.package}/bin/swayosd-client --output-volume mute-toggle";
          "--release XF86AudioMicMute" = "exec ${config.services.swayosd.package}/bin/swayosd-client --input-volume mute-toggle";
          "--release XF86MonBrightnessUp" = "exec ${config.services.swayosd.package}/bin/swayosd-client --brightness raise";
          "--release XF86MonBrightnessDown" = "exec ${config.services.swayosd.package}/bin/swayosd-client --brightness lower";
          "--release Caps_Lock" = "exec ${config.services.swayosd.package}/bin/swayosd-client --caps-lock";
          "XF86AudioPlay" = "exec ${config.services.swayosd.package}/bin/swayosd-client --playerctl play-pause";
          "XF86AudioNext" = "exec ${config.services.swayosd.package}/bin/swayosd-client --playerctl next";
          "XF86AudioPrev" = "exec ${config.services.swayosd.package}/bin/swayosd-client --playerctl previous";
          "Control+KP_End" = "exec ${config.services.swayosd.package}/bin/swayosd-client --playerctl previous";
          "Control+KP_Down" = "exec ${config.services.swayosd.package}/bin/swayosd-client --playerctl play-pause";
          "Control+KP_Next" = "exec ${config.services.swayosd.package}/bin/swayosd-client --playerctl next";
          "Mod4+Control+Shift+f" = "exec ${pkgs.foot}/bin/foot -- ${pkgs.yazi}/bin/yazi";
          "Control+Shift+Escape" = "exec ${pkgs.foot}/bin/foot -- ${pkgs.htop}/bin/htop";
          "Mod4+Return" = "exec ${pkgs.foot}/bin/foot";
          "Mod4+b" = "exec $HOME/.nix-profile/bin/firefox";
          "Mod4+Control+Shift+d" = "exec ${pkgs.rofi-pass-wayland}/bin/rofi-pass";
          "Mod4+d" = "exec ${config.programs.rofi.package}/bin/rofi -show drun";
          "Mod4+c" = "exec ${config.programs.rofi.package}/bin/rofi -show calc";
          "Mod4+space" = "exec ${pkgs.dunst}/bin/dunstctl close-all";
          "Mod4+Shift+q" = "kill";
          "Mod4+Shift+c" = "reload";
          "Mod4+Shift+e" = "exec ${pkgs.wlogout}/bin/wlogout";
          "Mod4+Alt_L" = "exec $HOME/.nix-profile/bin/clipboard-picker";
          "Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy";
          "Mod4+KP_Delete" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy";
          "Shift+Print" = "mode screenshot";
          "Mod4+Shift+KP_Delete" = "mode screenshot";
          "Mod4+l" = "exec ${swaylockCmd} -f";
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
          args = ["-dmenu" "-i" "-markup-rows" "-p" "{prompt}"];
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
          command = "${swaylockCmd} -f";
        }
        {
          timeout = 1200;
          command = "swaymsg \"output * dpms off\"";
          resumeCommand = "swaymsg \"output * dpms on\"";
        }
      ];
      events = {
        before-sleep = "${swaylockCmd} -f";
      };
    };
  };
}
