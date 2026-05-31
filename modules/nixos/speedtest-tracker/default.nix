{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.services.speedtest-tracker;
  inherit (lib) optionalAttrs types;

  package =
    if cfg.package ? override
    then cfg.package.override {dataDir = cfg.dataDir;}
    else cfg.package;

  phpPackage = package.passthru.phpPackage;
  phpBin = lib.getExe phpPackage;
  appDir = "${package}/share/php/speedtest-tracker";

  mkEnvValue = value:
    if builtins.isBool value
    then
      if value
      then "true"
      else "false"
    else if builtins.isInt value
    then toString value
    else let
      escaped = lib.replaceStrings ["\\" "\""] ["\\\\" "\\\""] (toString value);
    in "\"${escaped}\"";

  envAttrs =
    {
      APP_NAME = cfg.appName;
      APP_ENV = "production";
      APP_DEBUG = false;
      APP_URL = cfg.appURL;
      APP_LOCALE = cfg.appLocale;
      APP_FALLBACK_LOCALE = cfg.appFallbackLocale;
      APP_FAKER_LOCALE = cfg.appFakerLocale;
      LOG_CHANNEL = "stack";
      LOG_STACK = "single";
      LOG_LEVEL = "info";
      DB_CONNECTION = cfg.database;
      BROADCAST_CONNECTION = "log";
      FILESYSTEM_DISK = "local";
      QUEUE_CONNECTION = "database";
      CACHE_STORE = "database";
      MAIL_MAILER = "smtp";
      MAIL_HOST = "localhost";
      MAIL_PORT = 25;
      MAIL_FROM_ADDRESS = "hello@example.com";
      MAIL_FROM_NAME = cfg.appName;
      SESSION_DRIVER = "cookie";
      SESSION_LIFETIME = 10080;
      SESSION_ENCRYPT = false;
      SESSION_PATH = "/";
      DISPLAY_TIMEZONE = cfg.displayTimeZone;
      ADMIN_NAME = cfg.adminName;
      ADMIN_EMAIL = cfg.adminEmail;
      ADMIN_PASSWORD = cfg.adminPassword;
    }
    // optionalAttrs (cfg.assetURL != null) {
      ASSET_URL = cfg.assetURL;
    }
    // optionalAttrs (cfg.appTimeZone != null) {
      APP_TIMEZONE = cfg.appTimeZone;
    }
    // optionalAttrs (cfg.allowedIPs != []) {
      ALLOWED_IPS = lib.concatStringsSep "," cfg.allowedIPs;
    }
    // {
      CHART_BEGIN_AT_ZERO = cfg.chartBeginAtZero;
      CHART_DATETIME_FORMAT = cfg.chartDateTimeFormat;
      DATETIME_FORMAT = cfg.dateTimeFormat;
      CONTENT_WIDTH = cfg.contentWidth;
      PUBLIC_DASHBOARD = cfg.publicDashboard;
      DEFAULT_CHART_RANGE = cfg.defaultChartRange;
      SPEEDTEST_SCHEDULE = cfg.schedule;
      THRESHOLD_ENABLED = cfg.thresholds.enable;
      THRESHOLD_DOWNLOAD = cfg.thresholds.download;
      THRESHOLD_UPLOAD = cfg.thresholds.upload;
      THRESHOLD_PING = cfg.thresholds.ping;
      PRUNE_RESULTS_OLDER_THAN = cfg.pruneResultsOlderThan;
      API_RATE_LIMIT = cfg.api.rateLimit;
      API_MAX_RESULTS = cfg.api.maxResults;
    }
    // optionalAttrs (cfg.speedtest.skipIPs != []) {
      SPEEDTEST_SKIP_IPS = lib.concatStringsSep "," cfg.speedtest.skipIPs;
    }
    // optionalAttrs (cfg.speedtest.servers != []) {
      SPEEDTEST_SERVERS = lib.concatStringsSep "," (map toString cfg.speedtest.servers);
    }
    // optionalAttrs (cfg.speedtest.blockedServers != []) {
      SPEEDTEST_BLOCKED_SERVERS = lib.concatStringsSep "," (map toString cfg.speedtest.blockedServers);
    }
    // optionalAttrs (cfg.speedtest.interface != null) {
      SPEEDTEST_INTERFACE = cfg.speedtest.interface;
    }
    // optionalAttrs (cfg.speedtest.externalIPURL != null) {
      SPEEDTEST_EXTERNAL_IP_URL = cfg.speedtest.externalIPURL;
    }
    // optionalAttrs (cfg.speedtest.internetCheckHostname != null) {
      SPEEDTEST_INTERNET_CHECK_HOSTNAME = cfg.speedtest.internetCheckHostname;
    }
    // optionalAttrs (cfg.database == "sqlite") {
      DB_DATABASE = "${toString cfg.dataDir}/database/database.sqlite";
    }
    // optionalAttrs (cfg.database != "sqlite") cfg.dbSettings
    // cfg.settings;

  envFile = pkgs.writeText "speedtest-tracker.env" (
    lib.concatLines (lib.mapAttrsToList (name: value: "${name}=${mkEnvValue value}") envAttrs)
  );

  prometheusSetup = pkgs.writeText "speedtest-tracker-prometheus.php" ''
    <?php

    require "${appDir}/vendor/autoload.php";

    $app = require "${appDir}/bootstrap/app.php";
    $kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
    $kernel->bootstrap();

    $settings = app(App\Settings\DataIntegrationSettings::class);
    $settings->prometheus_enabled = ${
      if cfg.prometheus.enable
      then "true"
      else "false"
    };
    $settings->prometheus_allowed_ips = json_decode(${builtins.toJSON (builtins.toJSON cfg.prometheus.allowedIPs)}, true, 512, JSON_THROW_ON_ERROR);
    $settings->save();

    if ($settings->prometheus_enabled) {
        $latestCompleted = App\Models\Result::query()
            ->where('status', App\Enums\ResultStatus::Completed)
            ->latest('id')
            ->value('id');

        if ($latestCompleted !== null) {
            Illuminate\Support\Facades\Cache::forever('prometheus:latest_result', $latestCompleted);
        }
    }
  '';

  artisan = pkgs.writeShellScriptBin "speedtest-tracker" ''
    exec ${phpBin} ${lib.escapeShellArg "${appDir}/artisan"} "$@"
  '';
in {
  options.my.services.speedtest-tracker = {
    enable = lib.mkEnableOption "native Speedtest Tracker service";

    package = lib.mkPackageOption pkgs "speedtest-tracker" {};

    user = lib.mkOption {
      type = lib.types.str;
      default = "speedtest-tracker";
      description = "User the service runs as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "speedtest-tracker";
      description = "Group the service runs as.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8787;
      description = "Local port for the Speedtest Tracker web interface.";
    };

    dataDir = lib.mkOption {
      type = types.path;
      default = "/var/lib/speedtest-tracker";
      description = "Writable state directory for Speedtest Tracker.";
    };

    appName = lib.mkOption {
      type = types.str;
      default = "Speedtest Tracker";
      description = "APP_NAME used in the UI and notifications.";
    };

    appURL = lib.mkOption {
      type = types.str;
      default = "http://127.0.0.1:${toString cfg.port}";
      defaultText = lib.literalExpression ''
        "http://127.0.0.1:${toString cfg.port}"
      '';
      description = "External URL used by Speedtest Tracker for generated links.";
    };

    assetURL = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional ASSET_URL for reverse proxy setups.";
    };

    appLocale = lib.mkOption {
      type = types.str;
      default = "en";
      description = "Default application locale.";
    };

    appFallbackLocale = lib.mkOption {
      type = types.str;
      default = "en";
      description = "Fallback locale.";
    };

    appFakerLocale = lib.mkOption {
      type = types.str;
      default = "en_US";
      description = "Faker locale.";
    };

    appTimeZone = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional APP_TIMEZONE override.";
    };

    allowedIPs = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Restrict application access to these IPs or CIDRs.";
    };

    appKey = lib.mkOption {
      type = types.str;
      default = "";
      description = "Laravel APP_KEY. Leave empty to generate and persist one automatically.";
    };

    database = lib.mkOption {
      type = types.enum ["sqlite" "mysql" "mariadb" "pgsql"];
      default = "sqlite";
      description = "Database driver to use.";
    };

    dbSettings = lib.mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Extra database-related environment variables for non-SQLite backends.";
    };

    adminName = lib.mkOption {
      type = types.str;
      default = "Admin";
      description = "Initial admin display name used on first migration.";
    };

    adminEmail = lib.mkOption {
      type = types.str;
      default = "admin@example.com";
      description = "Initial admin email used on first migration.";
    };

    adminPassword = lib.mkOption {
      type = types.str;
      default = "password";
      description = "Initial admin password used on first migration.";
    };

    chartBeginAtZero = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Whether charts begin at zero.";
    };

    chartDateTimeFormat = lib.mkOption {
      type = types.str;
      default = "M. j - G:i";
      description = "Chart timestamp format.";
    };

    dateTimeFormat = lib.mkOption {
      type = types.str;
      default = "M. j, Y g:ia";
      description = "Table and notification timestamp format.";
    };

    displayTimeZone = lib.mkOption {
      type = types.str;
      default = config.time.timeZone;
      defaultText = lib.literalExpression "config.time.timeZone";
      description = "Display timezone shown in the UI.";
    };

    contentWidth = lib.mkOption {
      type = types.str;
      default = "7xl";
      description = "Filament content width token.";
    };

    publicDashboard = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Enable the public dashboard for unauthenticated users.";
    };

    defaultChartRange = lib.mkOption {
      type = types.enum ["24h" "week" "month"];
      default = "24h";
      description = "Default dashboard chart range.";
    };

    schedule = lib.mkOption {
      type = types.str;
      default = "";
      example = "0 * * * *";
      description = "Cron expression for scheduled speedtests. Empty disables scheduling.";
    };

    speedtest = {
      skipIPs = lib.mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Public IPs or CIDRs that should skip scheduled tests.";
      };

      servers = lib.mkOption {
        type = types.listOf types.int;
        default = [];
        description = "Preferred Ookla server IDs.";
      };

      blockedServers = lib.mkOption {
        type = types.listOf types.int;
        default = [];
        description = "Ookla server IDs to avoid.";
      };

      interface = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional network interface name used for tests.";
      };

      externalIPURL = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional URL used to determine the external WAN IP.";
      };

      internetCheckHostname = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional hostname used to check internet reachability.";
      };
    };

    thresholds = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Enable initial threshold configuration.";
      };

      download = lib.mkOption {
        type = types.int;
        default = 0;
        description = "Initial download threshold.";
      };

      upload = lib.mkOption {
        type = types.int;
        default = 0;
        description = "Initial upload threshold.";
      };

      ping = lib.mkOption {
        type = types.int;
        default = 0;
        description = "Initial ping threshold.";
      };
    };

    pruneResultsOlderThan = lib.mkOption {
      type = types.int;
      default = 0;
      description = "Prune stored results older than this many days. Zero disables pruning.";
    };

    api = {
      rateLimit = lib.mkOption {
        type = types.int;
        default = 60;
        description = "API requests per minute.";
      };

      maxResults = lib.mkOption {
        type = types.int;
        default = 500;
        description = "Maximum number of API results returned.";
      };
    };

    settings = lib.mkOption {
      type = types.attrsOf (types.oneOf [types.str types.int types.bool]);
      default = {};
      example = {
        SPEEDTEST_SCHEDULE = "0 */6 * * *";
        PUBLIC_DASHBOARD = true;
      };
      description = "Additional environment variables to write into the application .env file.";
    };

    prometheus.enable = lib.mkEnableOption "Prometheus metrics endpoint";

    prometheus.allowedIPs = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["127.0.0.1" "192.168.1.0/24"];
      description = "Allowed IP addresses or CIDRs for the /prometheus endpoint.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.database
          == "sqlite"
          || lib.all (name: builtins.hasAttr name cfg.dbSettings) [
            "DB_HOST"
            "DB_PORT"
            "DB_DATABASE"
            "DB_USERNAME"
          ];
        message = "my.services.speedtest-tracker.dbSettings must define DB_HOST, DB_PORT, DB_DATABASE and DB_USERNAME when using a non-SQLite database.";
      }
    ];

    environment.systemPackages = [artisan];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = toString cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = {};

    systemd.tmpfiles.rules = [
      "d ${toString cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/bootstrap 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/bootstrap/cache 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/database 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/storage 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/storage/app 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/storage/framework 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/storage/framework/cache 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/storage/framework/cache/data 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/storage/framework/sessions 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/storage/framework/testing 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/storage/framework/views 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/storage/logs 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.speedtest-tracker-setup = {
      description = "Prepare Speedtest Tracker runtime state";
      before = [
        "speedtest-tracker-web.service"
        "speedtest-tracker-queue.service"
        "speedtest-tracker-schedule.service"
      ];
      requiredBy = [
        "speedtest-tracker-web.service"
        "speedtest-tracker-queue.service"
        "speedtest-tracker-schedule.service"
      ];
      restartTriggers = [
        package
        envFile
        prometheusSetup
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = appDir;
        ReadWritePaths = [(toString cfg.dataDir)];
      };
      script = ''
        set -euo pipefail

        rm -f ${lib.escapeShellArg "${toString cfg.dataDir}/bootstrap/cache/packages.php"}
        rm -f ${lib.escapeShellArg "${toString cfg.dataDir}/bootstrap/cache/services.php"}

        configured_app_key=${lib.escapeShellArg cfg.appKey}

        if [ -n "$configured_app_key" ]; then
          app_key="$configured_app_key"
        else
          key_file=${lib.escapeShellArg "${toString cfg.dataDir}/app-key"}

          if [ ! -s "$key_file" ]; then
            printf 'base64:%s' "$(${pkgs.coreutils}/bin/head -c 32 /dev/urandom | ${pkgs.coreutils}/bin/base64 -w0)" > "$key_file"
            ${pkgs.coreutils}/bin/chmod 0600 "$key_file"
          fi

          app_key="$(${pkgs.coreutils}/bin/cat "$key_file")"
        fi

        ${lib.optionalString (cfg.database == "sqlite") ''
          ${pkgs.coreutils}/bin/touch ${lib.escapeShellArg "${toString cfg.dataDir}/database/database.sqlite"}
        ''}

        {
          ${pkgs.coreutils}/bin/cat ${envFile}
          printf 'APP_KEY="%s"\n' "$app_key"
        } > ${lib.escapeShellArg "${toString cfg.dataDir}/.env"}

        ${pkgs.coreutils}/bin/chmod 0640 ${lib.escapeShellArg "${toString cfg.dataDir}/.env"}

        ${phpBin} ${lib.escapeShellArg "${appDir}/artisan"} migrate --force --no-interaction
        ${phpBin} ${prometheusSetup}
      '';
    };

    systemd.services.speedtest-tracker-web = {
      description = "Speedtest Tracker web service";
      after = ["network-online.target" "speedtest-tracker-setup.service"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      environment = {
        HOME = toString cfg.dataDir;
      };
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = appDir;
        Restart = "always";
        RestartSec = 5;
        ReadWritePaths = [(toString cfg.dataDir)];
      };
      script = ''
        exec ${phpBin} ${lib.escapeShellArg "${appDir}/artisan"} serve --host=127.0.0.1 --port=${toString cfg.port}
      '';
    };

    systemd.services.speedtest-tracker-queue = {
      description = "Speedtest Tracker queue worker";
      after = ["network-online.target" "speedtest-tracker-setup.service"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      environment = {
        HOME = toString cfg.dataDir;
      };
      path = [pkgs.ookla-speedtest];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = appDir;
        Restart = "always";
        RestartSec = 5;
        ReadWritePaths = [(toString cfg.dataDir)];
      };
      script = ''
        exec ${phpBin} ${lib.escapeShellArg "${appDir}/artisan"} queue:work --sleep=3 --tries=3 --timeout=120 --no-interaction
      '';
    };

    systemd.services.speedtest-tracker-schedule = {
      description = "Run Speedtest Tracker scheduler";
      after = ["speedtest-tracker-setup.service"];
      requires = ["speedtest-tracker-setup.service"];
      environment = {
        HOME = toString cfg.dataDir;
      };
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = appDir;
        ReadWritePaths = [(toString cfg.dataDir)];
      };
      script = ''
        exec ${phpBin} ${lib.escapeShellArg "${appDir}/artisan"} schedule:run --no-interaction
      '';
    };

    systemd.timers.speedtest-tracker-schedule = {
      description = "Trigger Speedtest Tracker scheduler";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*:0/1";
        Persistent = true;
        Unit = "speedtest-tracker-schedule.service";
      };
    };
  };
}
