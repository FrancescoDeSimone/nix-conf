{config, lib, pkgs, ...}: let
  cfg = config.my.services.deemix;
in {
  options.my.services.deemix = {
    enable = lib.mkEnableOption "deemix webui";

    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/bambanah/deemix:latest";
      description = "OCI image for deemix.";
    };

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
      description = "User to run deemix (PUID).";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "deemix";
      description = "Group to run deemix (PGID).";
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
      "d ${cfg.dataDir} 0755 thinkcentre thinkcentre -"
      "d ${cfg.musicDir} 0755 thinkcentre thinkcentre -"
    ];

    virtualisation.oci-containers.containers.deemix = {
      image = cfg.image;
      autoStart = true;
      ports = ["127.0.0.1:${toString config.my.services.deemix.port}:6595"];
      volumes = [
        "${cfg.dataDir}:/config"
        "${cfg.musicDir}:/downloads"
      ];
      environment = {
        DEEMIX_SERVER_PORT = "6595";
        DEEMIX_DATA_DIR = "/config";
        DEEMIX_MUSIC_DIR = "/downloads";
        DEEMIX_HOST = cfg.host;
        DEEMIX_SINGLE_USER = if cfg.singleUser then "true" else "false";
        PUID = "1000";
        PGID = "1000";
        UMASK_SET = "022";
      };
      extraOptions = ["--pull=always"];
    };

    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [config.my.services.deemix.port];
  };
}
