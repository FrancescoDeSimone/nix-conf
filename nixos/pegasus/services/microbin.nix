{
  config,
  lib,
  private,
  ...
}: let
  port = config.my.services.microbin.port;
  hostAddress = "192.168.104.10";
  localAddress = "192.168.104.11";
  stateDir = "/var/lib/microbin";

  # MicroBin loads served files into RAM, so keep these small.
  # The nginx client_max_body_size for the public vhost must stay in sync
  maxUnencryptedMB = 64;
  maxEncryptedMB = 16;
in {
  age.secrets."microbin-admin" = {
    file = ../../../secrets/microbin-admin.age;
    mode = "0400";
  };

  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-microbin"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  # Ephemeral RAM-only storage: all MicroBin data lives on a 2 GB tmpfs
  # inside the container. A public pastebin can never fill the host disk,
  # and uploads evaporate on reboot/restart (abuse self-cleans).
  containers.microbin = {
    autoStart = true;
    privateNetwork = true;
    inherit hostAddress localAddress;

    bindMounts = {
      "/run/agenix/microbin-admin" = {
        hostPath = config.age.secrets."microbin-admin".path;
        isReadOnly = true;
      };
    };

    tmpfs = ["${stateDir}:size=2G,mode=0755,nosuid,nodev,noatime"];

    config = {pkgs, ...}: {
      users.users.microbin = {
        isSystemUser = true;
        group = "microbin";
      };
      users.groups.microbin = {};

      services.microbin = {
        enable = true;
        dataDir = stateDir;
        passwordFile = "/run/agenix/microbin-admin";
        settings = {
          MICROBIN_PORT = port;
          MICROBIN_BIND = "0.0.0.0";
          MICROBIN_DATA_DIR = stateDir;
          MICROBIN_THREADS = 1;

          MICROBIN_NO_LISTING = true;
          MICROBIN_PRIVATE = true;
          MICROBIN_ENABLE_READONLY = true;
          MICROBIN_EDITABLE = false;
          MICROBIN_ETERNAL_PASTA = false;
          MICROBIN_DEFAULT_EXPIRY = "24hour";
          MICROBIN_MAX_EXPIRY = "1week";
          MICROBIN_GC_DAYS = 30;
          MICROBIN_ENABLE_BURN_AFTER = true;
          MICROBIN_DEFAULT_BURN_AFTER = 0;

          MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = maxUnencryptedMB;
          MICROBIN_MAX_FILE_SIZE_ENCRYPTED_MB = maxEncryptedMB;
          MICROBIN_ENCRYPTION_SERVER_SIDE = true;
          MICROBIN_ENCRYPTION_CLIENT_SIDE = true;
          MICROBIN_DEFAULT_PRIVACY = "unlisted";
          # preselect the "Automatic" detection entry via footer HTML
          MICROBIN_FOOTER_TEXT = ''<script>var s=document.getElementById("syntax_highlight");if(s){s.value="auto";}var p=document.getElementById("privacy");if(p){p.value="unlisted";}</script>'';

          MICROBIN_HIGHLIGHTSYNTAX = true;
          MICROBIN_QR = false;
          MICROBIN_TITLE = "Fdesi Paste";
          MICROBIN_PUBLIC_PATH = "https://paste.${private.nginx.domain}";

          MICROBIN_DISABLE_TELEMETRY = true;
          MICROBIN_DISABLE_UPDATE_CHECKING = true;
          MICROBIN_LIST_SERVER = false;
        };
      };

      # hitting MemoryMax OOM-kills just this service, not the container.
      systemd.services.microbin.serviceConfig = {
        MemoryMax = "1G";
        CPUQuota = "100%";
        Restart = "always";
        RestartSec = "5s";
        DynamicUser = lib.mkForce false;
        User = "microbin";
        Group = "microbin";
      };

      # if fills up, wipe everything and start fresh automatically
      # sudo nixos-container run microbin -- df -h /var/lib/microbin
      systemd.services.microbin-space-watch = {
        description = "Wipe MicroBin tmpfs when full (ephemeral pastebin)";
        serviceConfig.Type = "oneshot";
        script = ''
          set -euo pipefail
          use=$(${pkgs.coreutils}/bin/df --output=pcent "${stateDir}" | tail -1 | tr -dc '0-9')
          if [ "''${use}" -ge 98 ]; then
            echo "microbin tmpfs at ''${use}% of 2G - wiping all uploads" >&2
            # Must stop first: wiping files out from under the running SQLite
            # DB would leak space via open file handles instead of freeing it.
            ${config.systemd.package}/bin/systemctl stop microbin.service || true
            ${pkgs.findutils}/bin/find "${stateDir}" -mindepth 1 -delete
            ${config.systemd.package}/bin/systemctl start microbin.service
            echo "microbin tmpfs wiped, service restarted"
          fi
        '';
      };
      systemd.timers.microbin-space-watch = {
        description = "MicroBin tmpfs fullness check";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*:0/5";
          Persistent = true;
        };
      };

      system.stateVersion = "25.11";

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [port];
      };

      networking.resolvconf.enable = false;
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };
}
