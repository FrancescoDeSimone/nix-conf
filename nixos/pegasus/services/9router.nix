{
  config,
  pkgs,
  inputs,
  ...
}: let
  hostPkgs = pkgs;
  routerPkg = pkgs.unstable._9router;
  headroomPkg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.headroom-ai;
  routerPort = config.my.services._9router.port;
  headroomPort = 8787;
  hostAddress = "192.168.105.10";
  localAddress = "192.168.105.11";
  routerStateDir = "/var/lib/9router";
  headroomStateDir = "/var/lib/headroom";

  openaiApiUrl = "https://api.openai.com";
in {
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-9router"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  systemd.tmpfiles.rules = [
    "d ${headroomStateDir} 0755 root root -"
  ];

  environment.etc."resolv-9router-container".text = "nameserver 8.8.8.8\n";

  containers."9router" = {
    autoStart = true;
    privateNetwork = true;
    inherit hostAddress localAddress;

    bindMounts = {
      "/var/lib/9router" = {
        hostPath = routerStateDir;
        isReadOnly = false;
      };
      "/var/lib/headroom" = {
        hostPath = headroomStateDir;
        isReadOnly = false;
      };
      "/run/agenix/9router-admin" = {
        hostPath = config.age.secrets."9router-admin".path;
        isReadOnly = true;
      };
      "/etc/resolv.conf" = {
        hostPath = "/etc/resolv-9router-container";
        isReadOnly = false;
      };
    };

    config = {...}: {
      users.users."9router" = {
        isSystemUser = true;
        group = "9router";
      };
      users.groups."9router" = {};
      users.users.headroom = {
        isSystemUser = true;
        group = "headroom";
      };
      users.groups.headroom = {};

      systemd.services."9router-chown" = {
        description = "Fix 9router state ownership after DynamicUser migration";
        before = ["9router.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig.Type = "oneshot";
        script = "${hostPkgs.coreutils}/bin/chown -R 9router:9router ${routerStateDir}";
      };

      systemd.services."9router" = {
        description = "9Router AI provider router";
        after = ["network-online.target" "9router-chown.service"];
        wants = ["network-online.target"];
        requires = ["9router-chown.service"];
        wantedBy = ["multi-user.target"];
        environment.HOME = routerStateDir;
        serviceConfig = {
          ExecStart = "${routerPkg}/bin/9router -n -l --skip-update -H 0.0.0.0 -p ${toString routerPort}";
          EnvironmentFile = "/run/agenix/9router-admin";
          User = "9router";
          Group = "9router";
          ReadWritePaths = [routerStateDir];
          Restart = "on-failure";
          RestartSec = 5;
          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          SystemCallArchitectures = "native";
        };
      };

      systemd.services.headroom-prepare = {
        description = "Prepare headroom state dir";
        before = ["headroom.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig.Type = "oneshot";
        script = "${hostPkgs.coreutils}/bin/chown -R headroom:headroom ${headroomStateDir}";
      };

      systemd.services.headroom = {
        description = "Headroom prompt-compression proxy (container localhost only)";
        after = ["network-online.target" "headroom-prepare.service" "9router.service"];
        wants = ["network-online.target"];
        requires = ["headroom-prepare.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = hostPkgs.writeShellScript "headroom-start" ''
            set -euo pipefail
            export HOME=${headroomStateDir}
            export HF_HOME=${headroomStateDir}/models
            export HEADROOM_BEACON=off DO_NOT_TRACK=1
            exec ${headroomPkg}/bin/headroom proxy \
              --host 127.0.0.1 --port ${toString headroomPort} \
              --openai-api-url ${openaiApiUrl} \
              --log-file ${headroomStateDir}/proxy.jsonl
          '';
          User = "headroom";
          Group = "headroom";
          Restart = "always";
          RestartSec = 5;
          MemoryMax = "4G";
          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [headroomStateDir];
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [routerPort];
      };

      networking.resolvconf.enable = false;
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";

      system.stateVersion = "25.11";
    };
  };
}
