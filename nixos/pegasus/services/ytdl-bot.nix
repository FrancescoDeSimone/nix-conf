{
  lib,
  config,
  pkgs,
  ...
}: let
  hostPkgs = pkgs;
  ytdl_bot = hostPkgs.ytdl-bot;
in {
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-ytdl-bot"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  containers.ytdl-bot = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.90.10";
    localAddress = "192.168.90.11";

    bindMounts = {
      "/run/agenix/ytdl-bot" = {
        hostPath = "/run/agenix/ytdl-bot";
        isReadOnly = true;
      };
    };

    config = {pkgs, ...}: {
      system.stateVersion = "25.11";

      environment.systemPackages = [
        pkgs.cargo
        pkgs.rustc
        pkgs.curl
        hostPkgs.unstable.yt-dlp
        hostPkgs.unstable.gallery-dl
      ];

      systemd.tmpfiles.rules = [
        "d /var/lib/yt-dlp 0755 root root -"
        "d /var/lib/gallery-dl 0755 root root -"
      ];

      systemd.services.dl-tools-update = {
        description = "Update yt-dlp and gallery-dl to the latest GitHub releases";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail

          ytmp="$(mktemp /var/lib/yt-dlp/.yt-dlp.XXXXXX)"
          ${pkgs.curl}/bin/curl --fail --silent --show-error --location --retry 3 \
            https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o "$ytmp"
          chmod 0755 "$ytmp"
          mv -f "$ytmp" /var/lib/yt-dlp/yt-dlp

          gtmp="$(mktemp /var/lib/gallery-dl/.gallery-dl.XXXXXX)"
          ${pkgs.curl}/bin/curl --fail --silent --show-error --location --retry 3 \
            https://github.com/mikf/gallery-dl/releases/latest/download/gallery-dl.bin -o "$gtmp"
          chmod 0755 "$gtmp"
          mv -f "$gtmp" /var/lib/gallery-dl/gallery-dl
        '';
      };

      systemd.timers.dl-tools-update = {
        description = "Check for yt-dlp and gallery-dl updates hourly";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
          Unit = "dl-tools-update.service";
        };
      };

      systemd.services.ytdl-bot = {
        description = "Telegram YouTube download bot";
        after = ["network-online.target" "dl-tools-update.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        path = [
          "/var/lib/yt-dlp"
          "/var/lib/gallery-dl"
          hostPkgs.curl
          hostPkgs.unstable.yt-dlp
          hostPkgs.unstable.gallery-dl
        ];
        serviceConfig = {
          EnvironmentFile = "/run/agenix/ytdl-bot";
          ExecStart = "${ytdl_bot}/bin/ytdl_bot";
          Restart = "always";
          RestartSec = 5;
        };
      };

      networking.firewall.enable = true;
      networking.resolvconf.enable = false;
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };
}
