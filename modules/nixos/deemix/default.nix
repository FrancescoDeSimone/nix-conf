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

    arlFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "File containing Deezer ARL (e.g. /run/agenix/deemix-arl). If set, login.json will be populated declaratively.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
      extraGroups = ["thinkcentre"];
    };

    users.groups.${cfg.group} = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/logs 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/config 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/queue 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/data 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.musicDir} 0775 thinkcentre thinkcentre -"
    ];

    systemd.services.deemix = {
      description = "deemix webui";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      environment = {
        DEEMIX_SERVER_PORT = "6595";
        DEEMIX_DATA_DIR = "/config";
        DEEMIX_MUSIC_DIR = "/downloads";
        DEEMIX_HOST = cfg.host;
        DEEMIX_SINGLE_USER = if cfg.singleUser then "true" else "false";
        PUID = "1000";
        PGID = "976";
        UMASK_SET = "022";
      };
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/deemix-webui";
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        RestartSec = 5;
        StateDirectory = "deemix";
        StateDirectoryMode = "0750";
        ReadWritePaths = [cfg.dataDir cfg.musicDir];
      } // lib.optionalAttrs (cfg.arlFile != null) {
        LoadCredential = "deemix-arl:${cfg.arlFile}";
      };
      preStart = lib.optionalString (cfg.arlFile != null) ''
        set -euo pipefail
        credFile="''${CREDENTIALS_DIRECTORY:-/run/credentials/deemix.service}/deemix-arl"
        if [[ ! -f "$credFile" ]]; then
          credFile="${cfg.arlFile}"
        fi
        if [[ -f "$credFile" ]]; then
          arl="$(tr -d '\r\n' < "$credFile" | xargs)"
          if [[ -n "$arl" ]]; then
            umask 077
            printf '{"arl":"%s"}\n' "$arl" > "${cfg.dataDir}/login.json.tmp"
            mv "${cfg.dataDir}/login.json.tmp" "${cfg.dataDir}/login.json"
            chown ${cfg.user}:${cfg.group} "${cfg.dataDir}/login.json"
            chmod 600 "${cfg.dataDir}/login.json"
          fi
        fi
      '';
    };

    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [config.my.services.deemix.port];
  };
}
