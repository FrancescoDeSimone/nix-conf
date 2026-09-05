{config, lib, pkgs, ...}: let
  cfg = config.my.services.deemix;
in {
  options.my.services.deemix = {
    enable = lib.mkEnableOption "deemix webui";

    package = lib.mkPackageOption pkgs "deemix" {};

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/deemix";
      description = "Config directory for deemix (DEEMIX_DATA_DIR).";
    };

    musicDir = lib.mkOption {
      type = lib.types.path;
      default = "/data/Media/Music";
      description = "Download directory for music (DEEMIX_MUSIC_DIR).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "deemix";
      description = "User to run deemix.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "deemix";
      description = "Group to run deemix.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host to bind (DEEMIX_HOST).";
    };

    singleUser = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable single user mode (DEEMIX_SINGLE_USER).";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall for deemix port.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.musicDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.deemix = {
      description = "deemix webui";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      environment = {
        DEEMIX_SERVER_PORT = toString config.my.services.deemix.port;
        DEEMIX_DATA_DIR = cfg.dataDir;
        DEEMIX_MUSIC_DIR = cfg.musicDir;
        DEEMIX_HOST = cfg.host;
        DEEMIX_SINGLE_USER = if cfg.singleUser then "true" else "false";
        NODE_ENV = "production";
      };
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/deemix-webui";
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        RestartSec = 5;
      };
    };

    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [config.my.services.deemix.port];
  };
}
