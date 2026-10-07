{
  config,
  pkgs,
  ...
}: let
  port = config.my.services._9router.port;
in {
  systemd.services."9router" = {
    description = "9Router AI provider router";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = "${pkgs.unstable._9router}/bin/9router -n -l --skip-update -H 127.0.0.1 -p ${toString port}";

      # Keeps its database and provider settings in ~/.9router, so HOME has to
      # point at the state directory; the dynamic user owns it.
      DynamicUser = true;
      StateDirectory = "9router";
      Environment = "HOME=/var/lib/9router";
      EnvironmentFile = config.age.secrets."9router-admin".path;

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
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      # No MemoryDenyWriteExecute: V8 needs writable executable memory.
    };
  };
}
