{ ... }: {
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
      exec-once = waybar, /nix/store/xi5hpn1rk47fgykpwxp9igny727g7z1s-profile/bin/wl-paste -t text --watch /nix/store/xi5hpn1rk47fgykpwxp9igny727g7z1s-profile/bin/clipman store
      exec = swaybg -i /home/fdesi/Downloads/ubuntu-24.04-wallpaper.jpg
      $terminal = foot
      env = XCURSOR_SIZE,24
      env = QT_QPA_PLATFORMTHEME,qt5ct # change to qt6ct if you have that
      # Example per-device config

      # Example windowrule v1
      # windowrule = float, ^(kitty)$
      # Example windowrule v2
      # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
      windowrulev2 = suppressevent maximize, class:.* # You'll probably like this.


      # See https://wiki.hyprland.org/Configuring/Keywords/ for more
      $mainMod = SUPER

      # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
      bind = $mainMod, Return, exec, $terminal
      bind = $mainMod SHIFT,Q, killactive,
      bind = $mainMod, V, togglefloating,
      bind = $mainMod, D, exec, /nix/store/xi5hpn1rk47fgykpwxp9igny727g7z1s-profile/bin/wofi --show drun
      bind = $mainMod, Alt_L,exec, /nix/store/xi5hpn1rk47fgykpwxp9igny727g7z1s-profile/bin/clipman pick --tool="wofi"
      bind = SUPER,Tab,cyclenext
      bindel=, XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bindel=, XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindl=, XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bind=$mainMod SHIFT, R,submap,resize
      bind=$mainMod,R,layoutmsg,swapwithmaster master

      bind = $mainMod, W, togglegroup,
      bind = $mainMod, Z, changegroupactive, b
      bind = $mainMod, X, changegroupactive, f

      # will start a submap called "resize"
      submap=resize

      # sets repeatable binds for resizing the active window
      binde=,right,resizeactive,10 0
      binde=,left,resizeactive,-10 0
      binde=,up,resizeactive,0 -10
      binde=,down,resizeactive,0 10

      # use reset to go back to the global submap
      bind=,escape,submap,reset

      # will reset the submap, which will return to the global submap
      submap=reset

      # keybinds further down will be global again..t

      # Move focus with mainMod + arrow keys
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d
      bind = $mainMod, F,    fullscreen
      bind= $mainMod,B,exec, firefox

      # Switch workspaces with mainMod + [0-9]
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10

      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10

      # Example special workspace (scratchpad)
      bind = $mainMod, S, togglespecialworkspace, magic
      bind = $mainMod SHIFT, S, movetoworkspace, special:magic

      # Scroll through existing workspaces with mainMod + scroll
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow
    '';
  };
}
