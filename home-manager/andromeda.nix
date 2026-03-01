{ outputs
, pkgs
, lib
, ...
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
    config.bars = [ ];
  };

  systemd.user.services.sworkstyle = lib.mkForce { };
  programs.waybar.settings.mainBar = {
    battery = lib.mkForce {
      bat = "BAT1";
      format = "{capacity}%";
      format-charging = "CHR {capacity}%";
      format-plugged = "AC {capacity}%";
    };
    pulseaudio = lib.mkForce {
      format = "VOL {volume}%";
      format-muted = "MUTED";
    };
    network = lib.mkForce {
      format-wifi = "{essid}";
      format-ethernet = "ETH";
      format-disconnected = "OFF";
    };
    backlight = lib.mkForce {
      format = "BRT {percent}%";
    };
    cpu = lib.mkForce {
      interval = 10;
      format = "C {usage}%";
    };
    memory = lib.mkForce {
      interval = 30;
      format = "M {percentage}%";
      tooltip-format = "{used:0.1f}G used";
    };
    disk = lib.mkForce {
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
