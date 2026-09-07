{config, lib, pkgs, ...}: let
  cfg = config.my.services.deemix-arr;
in {
  options.my.services.deemix-arr = {
    enable = lib.mkEnableOption "deemix-arr bridge (Torznab + torrent client for deemix)";

    package = lib.mkPackageOption pkgs "deemix-arr" {};

    deemixUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:${toString config.my.services.deemix.port}";
      description = "Deemix WebUI URL.";
    };

    musicDir = lib.mkOption {
      type = lib.types.path;
      default = config.my.services.deemix.musicDir;
      description = "Where deemix downloads music.";
    };

    stagingDir = lib.mkOption {
      type = lib.types.path;
      default = "/data/.deemix-arr-staging";
      description = "Same-filesystem staging dir for Lidarr imports.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "deemix";
      description = "Existing user to run deemix-arr (created by deemix module).";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "deemix";
      description = "Existing group to run deemix-arr.";
    };

    apiKey = lib.mkOption {
      type = lib.types.str;
      default = "deemix-arr";
      description = "API key for the Torznab endpoint (enter in Lidarr).";
    };

    qbUser = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Username for the fake qBittorrent client.";
    };

    qbPass = lib.mkOption {
      type = lib.types.str;
      default = "adminadmin";
      description = "Password for the fake qBittorrent client.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall for deemix-arr port.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.stagingDir} 0775 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.deemix-arr = {
      description = "deemix-arr bridge for Lidarr";
      after = ["network.target" "deemix.service"];
      wants = ["deemix.service"];
      wantedBy = ["multi-user.target"];
      environment.HOME = "/var/lib/deemix-arr";
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/deemix-arr --port ${toString cfg.port} --deemix-url ${cfg.deemixUrl} --music-dir ${cfg.musicDir} --staging-dir ${cfg.stagingDir} --state-dir /var/lib/deemix-arr --api-key ${cfg.apiKey} --qb-user ${cfg.qbUser} --qb-pass ${cfg.qbPass}";
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        RestartSec = 5;
        StateDirectory = "deemix-arr";
        StateDirectoryMode = "0750";
        ReadWritePaths = [cfg.stagingDir cfg.musicDir "/var/lib/deemix-arr"];
        UMask = "0002";
      };
    };

    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [cfg.port];
  };
}
