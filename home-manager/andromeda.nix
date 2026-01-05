{
  outputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./desktop/default.nix
    ./cli/default.nix
    ./desktop/wayland/default.nix
    ./cli/programming/default.nix
  ];

  home.packages = with pkgs; [
    jellyfin-tui
    unstable.freetube
    yq
    jq
    file
    ayugram-desktop
  ];

  wayland.windowManager.sway = {
    package = null;
    config.bars = [];
  };

  programs.waybar.settings.mainBar = {
    battery = {
      bat = "BAT1";
      format = "{capacity}%";
      format-charging = "CHR {capacity}%";
      format-plugged = "AC {capacity}%";
    };
    pulseaudio = {
      format = "VOL {volume}%";
      format-muted = "MUTED";
    };
    network = {
      format-wifi = "{essid}";
      format-ethernet = "ETH";
      format-disconnected = "OFF";
    };
    backlight = {
      format = "BRT {percent}%";
    };
    cpu = {
      interval = 10;
      format = "C {usage}%";
    };
    memory = {
      interval = 30;
      format = "M {percentage}%";
      tooltip-format = "{used:0.1f}G used";
    };
    disk = {
      interval = 30;
      format = "D {percentage_used}%";
      path = "/";
    };
  };

  home = {
    username = "fdesi";
    homeDirectory = "/home/fdesi";
    stateVersion = "25.11";
  };
}
