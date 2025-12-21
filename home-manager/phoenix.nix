{
  outputs,
  pkgs,
  ...
}: {
  imports = [./desktop/default.nix ./cli/default.nix ./desktop/wayland/default.nix];

  home.packages = with pkgs; [jellyfin-tui yq jq ayugram-desktop];
  modules.editors.neovim.extras = false;

  xdg.dataFile."wayland-sessions/sway-nvidia.desktop".text = ''
    [Desktop Entry]
    Name=Sway (Nvidia)
    Comment=An i3-compatible Wayland compositor
    Exec=env WLR_DRM_DEVICES=/dev/dri/card1:/dev/dri/card2 WLR_NO_HARDWARE_CURSORS=1 /usr/bin/sway --unsupported-gpu
    Type=Application
  '';
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
  programs.swaylock.package = null;
  home = {
    username = "fdesi";
    homeDirectory = "/home/fdesi";
  };
}
