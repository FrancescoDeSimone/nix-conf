{config, lib, pkgs, ...}: let
  cfg = config.my.services.uppy-companion;
in {
  options.my.services.uppy-companion = {
    enable = lib.mkEnableOption "Uppy Companion (remote import backend for OpenCloud importer)";

    package = lib.mkPackageOption pkgs "uppy-companion" {};

    domain = lib.mkOption {
      type = lib.types.str;
      default = "opencloud.${config.private.nginx.internalDomain}";
      description = "Public hostname Companion is served from.";
    };

    path = lib.mkOption {
      type = lib.types.str;
      default = "/companion";
      description = "Subpath Companion is served from (same origin as OpenCloud).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "uppy-companion";
      description = "User to run Companion.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "uppy-companion";
      description = "Group to run Companion.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/uppy-companion";
      description = "State and temp upload directory.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall for Companion port.";
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Extra env vars (e.g. provider OAuth keys).";
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

    systemd.services.uppy-companion = {
      description = "Uppy Companion";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      environment =
        {
          COMPANION_PORT = toString config.my.services.uppy-companion.port;
          COMPANION_DOMAIN = cfg.domain;
          COMPANION_PROTOCOL = "https";
          COMPANION_PATH = cfg.path;
          COMPANION_DATADIR = "${cfg.dataDir}/data";
          COMPANION_SELF_ENDPOINT = "http://127.0.0.1:${toString config.my.services.uppy-companion.port}${cfg.path}";
          COMPANION_CLIENT_ORIGINS = "https://${cfg.domain}";
          COMPANION_ENABLE_URL_ENDPOINT = "true";
        }
        // cfg.extraEnvironment;
      serviceConfig = {
        ExecStartPre = pkgs.writeShellScript "uppy-companion-secret" ''
          set -euo pipefail
          mkdir -p "${cfg.dataDir}" "${cfg.dataDir}/data"
          if [[ ! -f "${cfg.dataDir}/secret" ]]; then
            ${pkgs.openssl}/bin/openssl rand -hex 32 > "${cfg.dataDir}/secret"
            chmod 600 "${cfg.dataDir}/secret"
          fi
          chown -R ${cfg.user}:${cfg.group} "${cfg.dataDir}"
        '';
        ExecStart = pkgs.writeShellScript "uppy-companion-start" ''
          set -euo pipefail
          secret="$(tr -d '\r\n' < "${cfg.dataDir}/secret")"
          export COMPANION_SECRET="$secret"
          export COMPANION_PREAUTH_SECRET="$secret"
          exec "${cfg.package}/bin/companion"
        '';
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        RestartSec = 5;
        StateDirectory = "uppy-companion";
        StateDirectoryMode = "0750";
        ReadWritePaths = [cfg.dataDir];
        UMask = "0007";
      };
    };

    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [config.my.services.uppy-companion.port];
  };
}
