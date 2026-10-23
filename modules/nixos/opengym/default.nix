{
  config,
  lib,
  pkgs,
  private,
  ...
}: let
  inherit
    (lib)
    mapAttrs
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optionalAttrs
    types
    ;

  cfg = config.my.services.opengym;

  # The public vhost (defined in the host's nginx config) serves the PWA
  # from frontendPackage and proxies /api here. Passkeys (WebAuthn RP_ID)
  # and the API's CSRF origin check are bound to the public hostname, so
  # rpId/origin must match it — hence the derived defaults.
  defaultHost = "opengym.${private.nginx.domain}";

  apiEnv =
    {
      PORT = toString cfg.port;
      DATA_DIR = toString cfg.dataDir;
      RP_ID = cfg.rpId;
      ORIGIN = cfg.origin;
      RP_NAME = cfg.rpName;
      SESSION_DAYS = toString cfg.sessionDays;
      ALLOW_GUEST =
        if cfg.allowGuest
        then "1"
        else "0";
      INVITE_ONLY =
        if cfg.inviteOnly
        then "1"
        else "0";
      AUDIT_LOG =
        if cfg.auditLog
        then "1"
        else "0";
      AUDIT_MAX = toString cfg.auditMax;
    }
    // optionalAttrs (cfg.auditIp != null) {
      AUDIT_IP = cfg.auditIp;
    }
    // optionalAttrs (cfg.adminUids != "") {
      ADMIN_UIDS = cfg.adminUids;
    }
    // optionalAttrs cfg.firstUserAdmin {
      FIRST_USER_ADMIN = "1";
    }
    // (
      if cfg.trustProxy
      then {TRUST_PROXY = "1";}
      else {TRUST_PROXY = "0";}
    )
    // optionalAttrs cfg.passwordLogin {PASSWORD_LOGIN = "1";}
    # Last so users can override any derived value.
    // mapAttrs (_: v: toString v) cfg.settings;
in {
  options.my.services.opengym = {
    enable = mkEnableOption "the openGym gym & body-weight tracker API";

    package = mkPackageOption pkgs "opengym-api" {};

    frontendPackage = mkPackageOption pkgs "opengym-frontend" {};

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/opengym";
      description = "Persistent data directory (profiles, workouts, audit log, session key).";
    };

    rpId = mkOption {
      type = types.str;
      default = defaultHost;
      description = ''
        WebAuthn Relying Party ID: the hostname passkeys are registered for.
        Must match the public vhost's server_name (and be a domain suffix of
        every origin that signs in). Changing it invalidates all passkeys.
      '';
    };

    origin = mkOption {
      type = types.str;
      default = "https://${defaultHost}";
      description = "Full origin URL the app is served from; used for CSRF validation.";
    };

    rpName = mkOption {
      type = types.str;
      default = "openGym";
      description = "Display name shown in passkey registration prompts.";
    };

    sessionDays = mkOption {
      type = types.ints.unsigned;
      default = 90;
      description = "Sign-in session lifetime in days.";
    };

    passwordLogin = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Offer name-and-password sign-in next to passkeys. 'Create new
        profile' can use a password instead of a passkey, and profiles can
        set a sign-in e-mail. No password reset mail exists — an admin
        issues a one-time code from the dashboard.
      '';
    };

    trustProxy = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Let the sign-in throttle read the client address from
        X-Forwarded-For instead of the socket peer (true when behind nginx).
      '';
    };

    firstUserAdmin = mkOption {
      type = types.bool;
      default = false;
      description = "Make the profile created first on an empty instance the instance admin.";
    };

    allowGuest = mkOption {
      type = types.bool;
      default = true;
      description = "Offer 'Continue without account' guest mode.";
    };

    inviteOnly = mkOption {
      type = types.bool;
      default = false;
      description = "Require an invite code to create a profile.";
    };

    auditLog = mkOption {
      type = types.bool;
      default = true;
      description = "Record sign-ins and admin actions in the activity log.";
    };

    auditMax = mkOption {
      type = types.ints.unsigned;
      default = 5000;
      description = "Maximum audit events kept (0 = unlimited).";
    };

    auditIp = mkOption {
      type = types.nullOr (types.enum ["off" "net" "full"]);
      default = null;
      description = ''
        Record the caller's address: off, net (masked) or full. Leaving null
        keeps the API default (off) without setting AUDIT_IP at all.
      '';
    };

    adminUids = mkOption {
      type = types.lines;
      default = "";
      description = "Comma-separated list of profile IDs that get the admin dashboard.";
    };

    settings = mkOption {
      type = types.attrsOf (types.oneOf [types.str types.int types.bool]);
      default = {};
      example = {COACH_DISABLED = true;};
      description = ''
        Extra OGYM_* environment variables. These are applied last and can
        override any value derived from the options above.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.opengym-api = {
      description = "openGym gym & body-weight tracker API (passkeys + JSON data)";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      environment = apiEnv;

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/opengym-api";
        DynamicUser = true;
        StateDirectory = "opengym";
        # ProtectSystem=strict makes the tree read-only; StateDirectory covers
        # the default dataDir, ReadWritePaths the custom one.
        ReadWritePaths = [cfg.dataDir];

        Restart = "on-failure";
        RestartSec = 5;

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateDevices = true;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 - - -"
    ];
  };
}
