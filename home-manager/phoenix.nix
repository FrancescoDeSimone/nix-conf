{pkgs, ...}: {
  imports = [./desktop/default.nix ./cli/default.nix ./desktop/wayland/default.nix];

  home.packages = with pkgs; [jellyfin-tui yq jq ayugram-desktop uv git];
  modules.editors.neovim.extras = false;

  xdg.dataFile."wayland-sessions/sway-nvidia.desktop".text = ''
    [Desktop Entry]
    Name=Sway (Nvidia)
    Comment=An i3-compatible Wayland compositor
    Exec=env WLR_DRM_DEVICES=/dev/dri/card1:/dev/dri/card2 WLR_NO_HARDWARE_CURSORS=1 /usr/bin/sway --unsupported-gpu
    Type=Application
  '';
  # Bose AE2 SoundLink: pin Bluetooth audio to A2DP, no HSP/HFP headset profile.
  # Ubuntu 24.04 ships wireplumber 0.4 -> lua config; the .conf one is for 0.5+.
  xdg.configFile = {
    "wireplumber/bluetooth.lua.d/51-bluez-a2dp-only.lua".text = ''
      bluez_monitor.properties["bluez5.roles"] = "[ a2dp_sink a2dp_source ]"
    '';
    "wireplumber/policy.lua.d/51-bluetooth-pin-a2dp.lua".text = ''
      bluetooth_policy.policy["media-role.use-headset-profile"] = false
    '';
    "wireplumber/wireplumber.conf.d/50-bluez-disable-hsp.conf".text = ''
      monitor.bluez.properties = {
          bluez5.roles = [ a2dp_sink a2dp_source ]
      }
    '';
  };
  modules.desktop.sway.wallpaper = "/usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png";
  wayland.windowManager = {
    sway = {
      package = null;
      checkConfig = false;
      enable = true;
      config = {
        workspaceOutputAssign = [
          {
            workspace = "1";
            output = "DP-1";
          }
          {
            workspace = "2";
            output = "DP-1";
          }
          {
            workspace = "3";
            output = "DP-1";
          }
          {
            workspace = "4";
            output = "DP-1";
          }
          {
            workspace = "5";
            output = "DP-1";
          }
          {
            workspace = "6";
            output = "HDMI-A-1";
          }
          {
            workspace = "7";
            output = "HDMI-A-1";
          }
          {
            workspace = "8";
            output = "HDMI-A-1";
          }
          {
            workspace = "9";
            output = "HDMI-A-1";
          }
          {
            workspace = "10";
            output = "eDP-1";
          }
        ];
      };
    };
  };
  programs = {
    swaylock.package = null;
    mpv = {
      enable = true;
      package = pkgs.mpv;
      config = {
        vo = "wlshm";
        hwdec = "auto";
        msg-level = "ffmpeg=error";
        scale = "spline36";
        cscale = "spline36";
      };
    };
  };
  home = {
    username = "fdesi";
    homeDirectory = "/home/fdesi";
  };
}
