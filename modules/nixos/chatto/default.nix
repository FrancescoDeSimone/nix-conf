{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.services.chatto;
  inherit
    (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optional
    optionalAttrs
    optionalString
    concatLists
    concatMap
    concatStringsSep
    filter
    imap0
    listToAttrs
    mapAttrs
    unique
    types
    escapeShellArg
    ;

  dataDir = toString cfg.dataDir;

  passwordFiles = unique (filter (p: p != null) (map (u: u.passwordFile) cfg.bootstrapUsers));

  bootstrapUsersIndexed =
    imap0 (i: u: {
      inherit i u;
    })
    cfg.bootstrapUsers;

  bootstrapUserEnvAttrs = listToAttrs (concatLists (map ({
    i,
    u,
  }:
    [
      {
        name = "CHATTO_BOOTSTRAP_USERS_${toString i}_LOGIN";
        value = u.login;
      }
    ]
    ++ optional (u.email != null) {
      name = "CHATTO_BOOTSTRAP_USERS_${toString i}_EMAIL";
      value = u.email;
    }
    ++ optional (u.displayName != null) {
      name = "CHATTO_BOOTSTRAP_USERS_${toString i}_DISPLAY_NAME";
      value = u.displayName;
    }
    ++ optional (u.serverRole != null) {
      name = "CHATTO_BOOTSTRAP_USERS_${toString i}_SERVER_ROLE";
      value = u.serverRole;
    })
  bootstrapUsersIndexed));

  envAttrs =
    {CHATTO_WEBSERVER_PORT = toString cfg.port;}
    // optionalAttrs (cfg.url != null) {CHATTO_WEBSERVER_URL = cfg.url;}
    // optionalAttrs (cfg.trustedProxies != []) {CHATTO_WEBSERVER_TRUSTED_PROXIES = concatStringsSep "," cfg.trustedProxies;}
    // optionalAttrs (cfg.owners != []) {CHATTO_OWNERS_EMAILS = concatStringsSep "," cfg.owners;}
    // optionalAttrs cfg.video.enable {CHATTO_VIDEO_ENABLED = "true";}
    // optionalAttrs cfg.search.enable {
      CHATTO_SEARCH_ENABLED = "true";
      CHATTO_SEARCH_PROVIDER_ENABLED = "true";
      CHATTO_SEARCH_PROVIDER_DIRECTORY = "${dataDir}/search";
    }
    // optionalAttrs cfg.metrics.enable {
      CHATTO_METRICS_ENABLED = "true";
      CHATTO_METRICS_BIND_ADDRESS = cfg.metrics.bindAddress;
      CHATTO_METRICS_PORT = toString cfg.metrics.port;
    }
    // optionalAttrs cfg.operatorApi.enable {
      CHATTO_OPERATOR_API_ENABLED = "true";
      CHATTO_OPERATOR_API_SOCKET_PATH = cfg.operatorApi.socketPath;
    }
    // optionalAttrs (cfg.operatorApi.socketMode != null) {CHATTO_OPERATOR_API_SOCKET_MODE = cfg.operatorApi.socketMode;}
    // optionalAttrs (cfg.serverName != null) {CHATTO_BOOTSTRAP_SERVER_NAME = cfg.serverName;}
    // optionalAttrs (cfg.rooms != []) {CHATTO_BOOTSTRAP_SERVER_ROOMS = concatStringsSep "," cfg.rooms;}
    // bootstrapUserEnvAttrs
    // mapAttrs (_: v: toString v) cfg.settings;

  bootstrapEnvScript = concatStringsSep "\n" (concatMap ({
    i,
    u,
  }:
    optional (u.passwordFile != null) ''
      printf 'CHATTO_BOOTSTRAP_USERS_${toString i}_PASSWORD=%s\n' "$(${pkgs.coreutils}/bin/cat ${escapeShellArg (toString u.passwordFile)})"
    '')
  bootstrapUsersIndexed);
in {
  options.my.services.chatto = {
    enable = mkEnableOption "Chatto service";

    package = mkPackageOption pkgs "chatto" {};

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/chatto";
      description = "Persistent data directory for Chatto.";
    };

    hostAddress = mkOption {
      type = types.str;
      default = "192.168.80.10";
      description = "Host-side address of the Chatto container network.";
    };

    localAddress = mkOption {
      type = types.str;
      default = "192.168.80.11";
      description = "Address of the Chatto container inside its network.";
    };

    port = mkOption {
      type = types.port;
      default = 4000;
      description = "Port the Chatto webserver listens on.";
    };

    url = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Public URL where Chatto is reachable. Used for generating absolute links.";
    };

    trustedProxies = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["192.168.80.10/32"];
      description = "IPs or CIDRs of reverse proxies allowed to supply forwarded headers.";
    };

    serverName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Server name applied on first boot (bootstrap).";
    };

    rooms = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Initial rooms created on first boot (bootstrap).";
    };

    owners = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["admin@example.com"];
      description = "Email addresses that confer owner status.";
    };

    bootstrapUsers = mkOption {
      type = types.listOf (types.submodule {
        options = {
          login = mkOption {
            type = types.str;
            description = "Login for the bootstrap user.";
          };

          email = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Verified email for the bootstrap user.";
          };

          displayName = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Display name for the bootstrap user.";
          };

          passwordFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "File containing the bootstrap password. Applied on first boot only. The value must not contain newlines.";
          };

          serverRole = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "owner";
            description = "Server role assigned to the bootstrap user, e.g. owner, admin or moderator.";
          };
        };
      });
      default = [];
      description = "Users created on first boot (bootstrap).";
    };

    video = {
      enable = mkEnableOption "video processing (transcoding, thumbnails)";
    };

    search = {
      enable = mkEnableOption "message search and the bundled Bleve search provider";
    };

    metrics = {
      enable = mkEnableOption "Prometheus-compatible metrics endpoint";

      bindAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Address to bind the metrics listener to.";
      };

      port = mkOption {
        type = types.port;
        default = 9090;
        description = "Port for the metrics listener.";
      };
    };

    operatorApi = {
      enable = mkEnableOption "local operator API Unix socket";

      socketPath = mkOption {
        type = types.str;
        default = "/tmp/chatto/operator.sock";
        description = "Unix socket path for local operator commands.";
      };

      socketMode = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Permissions for the operator socket, e.g. 0660.";
      };
    };

    settings = mkOption {
      type = types.attrsOf (types.oneOf [types.str types.int types.bool]);
      default = {};
      example = {
        CHATTO_AUTH_DIRECT_REGISTRATION = true;
      };
      description = "Additional CHATTO_* environment variables to set.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.port
          != cfg.metrics.port
          || !cfg.metrics.enable;
        message = "my.services.chatto.port and my.services.chatto.metrics.port must differ when metrics are enabled.";
      }
      {
        assertion = lib.all (u:
          !lib.elem (lib.toLower u.login) [
            "root"
            "admin"
            "superuser"
            "op"
            "operator"
            "support"
          ])
        cfg.bootstrapUsers;
        message = "my.services.chatto.bootstrapUsers logins must not be reserved usernames (root, admin, superuser, op, operator, support).";
      }
    ];

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 - - -"
    ];

    containers.chatto = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = cfg.hostAddress;
      localAddress = cfg.localAddress;

      bindMounts =
        {
          "${dataDir}" = {
            hostPath = dataDir;
            isReadOnly = false;
          };
        }
        // listToAttrs (map (f: {
            name = toString f;
            value = {
              hostPath = toString f;
              isReadOnly = true;
            };
          })
          passwordFiles);

      config = {pkgs, ...}: {
        system.stateVersion = config.system.stateVersion;

        users.users.chatto = {
          isSystemUser = true;
          group = "chatto";
          home = dataDir;
          createHome = true;
        };
        users.groups.chatto = {};

        environment.systemPackages = optional cfg.video.enable pkgs.ffmpeg;

        systemd.tmpfiles.rules = [
          "d ${dataDir} 0750 chatto chatto -"
          "d ${dataDir}/search 0750 chatto chatto -"
          "d /tmp/chatto 0700 chatto chatto -"
        ];

        systemd.services.chatto-setup = {
          description = "Prepare Chatto runtime state";
          before = ["chatto.service"];
          requiredBy = ["chatto.service"];
          restartTriggers = [cfg.package];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -euo pipefail

            if [ ! -f ${dataDir}/chatto.toml ]; then
              ${cfg.package}/bin/chatto init -c ${dataDir}/chatto.toml
            fi
            chown chatto:chatto ${dataDir}/chatto.toml

            ${optionalString (bootstrapEnvScript != "") ''
              {
                ${bootstrapEnvScript}
              } > ${dataDir}/bootstrap.env
              chown chatto:chatto ${dataDir}/bootstrap.env
              chmod 0600 ${dataDir}/bootstrap.env
            ''}
          '';
        };

        systemd.services.chatto = {
          description = "Chatto server";
          documentation = ["https://docs.chatto.run"];
          wantedBy = ["multi-user.target"];
          after = ["network-online.target"];
          wants = ["network-online.target"];
          path = optional cfg.video.enable pkgs.ffmpeg;
          environment = envAttrs;
          serviceConfig =
            {
              ExecStart = "${cfg.package}/bin/chatto start -c ${dataDir}/chatto.toml";
              User = "chatto";
              Group = "chatto";
              Restart = "always";
              RestartSec = 5;
              WorkingDirectory = dataDir;
              StateDirectory = "chatto";
              StateDirectoryMode = "0750";
              LimitNOFILE = 65536;
            }
            // optionalAttrs (passwordFiles != []) {
              EnvironmentFile = ["${dataDir}/bootstrap.env"];
            };
        };

        networking.firewall = {
          enable = true;
          allowedTCPPorts = [cfg.port];
        };
      };
    };
  };
}
