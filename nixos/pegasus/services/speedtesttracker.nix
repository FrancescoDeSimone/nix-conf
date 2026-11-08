{
  config,
  private,
  ...
}: let
  domain = "speedtracker.${private.nginx.internalDomain}";
  dataDir = "/var/lib/speedtest-tracker";
  internalPort = config.my.services.speedtest-tracker.port;
in {
  services.speedtest-tracker = {
    enable = true;

    enableNginx = false;

    poolConfig."listen.group" = "nginx";

    settings = {
      APP_KEY_FILE = "${dataDir}/app-key";

      APP_NAME = "Speedtest Tracker";
      APP_ENV = "production";
      APP_DEBUG = false;
      APP_URL = "https://${domain}";
      APP_LOCALE = "en";
      APP_FALLBACK_LOCALE = "en";
      APP_FAKER_LOCALE = "en_US";
      LOG_CHANNEL = "stack";
      LOG_STACK = "single";
      LOG_LEVEL = "info";

      DB_CONNECTION = "sqlite";
      DB_DATABASE = "${dataDir}/database/database.sqlite";

      BROADCAST_CONNECTION = "log";
      FILESYSTEM_DISK = "local";
      QUEUE_CONNECTION = "database";
      CACHE_STORE = "database";

      MAIL_MAILER = "smtp";
      MAIL_HOST = "localhost";
      MAIL_PORT = 25;
      MAIL_FROM_ADDRESS = "hello@example.com";
      MAIL_FROM_NAME = "Speedtest Tracker";

      SESSION_DRIVER = "cookie";
      SESSION_LIFETIME = 10080;
      SESSION_ENCRYPT = false;
      SESSION_PATH = "/";

      DISPLAY_TIMEZONE = config.time.timeZone;
      ADMIN_NAME = "Admin";
      ADMIN_EMAIL = "admin@example.com";
      ADMIN_PASSWORD_FILE = config.age.secrets."speedtest-admin".path;

      CHART_BEGIN_AT_ZERO = true;
      CHART_DATETIME_FORMAT = "M. j - G:i";
      DATETIME_FORMAT = "M. j, Y g:ia";
      CONTENT_WIDTH = "7xl";
      PUBLIC_DASHBOARD = false;
      DEFAULT_CHART_RANGE = "24h";
      SPEEDTEST_SCHEDULE = "0 * * * *";
      THRESHOLD_ENABLED = false;
      THRESHOLD_DOWNLOAD = 0;
      THRESHOLD_UPLOAD = 0;
      THRESHOLD_PING = 0;
      PRUNE_RESULTS_OLDER_THAN = 0;
      API_RATE_LIMIT = 60;
      API_MAX_RESULTS = 500;
    };
  };

  services.nginx.virtualHosts."speedtracker-internal" = {
    listen = [{addr = "127.0.0.1"; port = internalPort;}];
    root = "${config.services.speedtest-tracker.package}/public";
    locations = {
      "/" = {
        tryFiles = "$uri $uri/ /index.php?$query_string";
        index = "index.php";
        extraConfig = ''
          sendfile off;
        '';
      };
      "~ \\.php$" = {
        extraConfig = ''
          include ${config.services.nginx.package}/conf/fastcgi_params;
          fastcgi_param SCRIPT_FILENAME $request_filename;
          fastcgi_param modHeadersAvailable true;
          fastcgi_pass unix:${config.services.phpfpm.pools.speedtest-tracker.socket};
        '';
      };
      "~ \\.(js|css|gif|png|ico|jpg|jpeg)$" = {
        extraConfig = "expires 365d;";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "r ${dataDir}/.env"
    "f ${dataDir}/database/database.sqlite 0640 speedtest-tracker speedtest-tracker -"
  ];
}
