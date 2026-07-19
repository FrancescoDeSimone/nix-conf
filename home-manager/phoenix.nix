{
  config,
  pkgs,
  ...
}: let
  tabbyPort = 5050;
  tabbyModelName = "qwen2.5-coder-3b";
  tabbyPromptTemplate = "qwen2.5";
  tabbyModelDir = "${config.home.homeDirectory}/.local/share/tabbyapi/models";
  tabbyDataDir = "${config.home.homeDirectory}/.local/share/tabbyapi";
  tabbySrcDir = "${tabbyDataDir}/src";
  tabbyVenvDir = "${tabbyDataDir}/venv";
  tabbyMain = "${tabbySrcDir}/main.py";
  tabbyPython = "${tabbyVenvDir}/bin/python";
in {
  imports = [./desktop/default.nix ./cli/default.nix ./desktop/wayland/default.nix];

  home.packages = with pkgs; [jellyfin-tui yq jq ayugram-desktop uv git];

  services.syncthing = {
    enable = true;
    tray.enable = true;
    overrideDevices = false;
    overrideFolders = false;
  };
  modules.editors.neovim.extras = false;


  xdg.dataFile."wayland-sessions/sway-nvidia.desktop".text = ''
    [Desktop Entry]
    Name=Sway (Nvidia)
    Comment=An i3-compatible Wayland compositor
    Exec=env WLR_DRM_DEVICES=/dev/dri/card1:/dev/dri/card2 WLR_NO_HARDWARE_CURSORS=1 /usr/bin/sway --unsupported-gpu
    Type=Application
  '';
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
            output = "DP-2";
          }
          {
            workspace = "2";
            output = "DP-2";
          }
          {
            workspace = "3";
            output = "DP-2";
          }
          {
            workspace = "4";
            output = "DP-2";
          }
          {
            workspace = "5";
            output = "DP-2";
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
