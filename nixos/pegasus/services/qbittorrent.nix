{
  private,
  pkgs,
  inputs,
  config,
  ...
}: let
  qbuser = private.qb.user;
  qbpasswd = private.qb.passwd;
in {
  services.qui = {
    enable = true;
    openFirewall = false;
    settings = {
      port = config.my.services.qui.port;
      host = "127.0.0.1";
    };
    secretFile = config.age.secrets.qui.path;
  };

  services.qbittorrent = {
    enable = true;
    user = "thinkcentre";
    group = "thinkcentre";
    profileDir = "/data/qbittorrent";
    openFirewall = false;

    serverConfig = {
      LegalNotice.Accepted = true;
      Preferences = {
        WebUI = {
          Enabled = true;
          Address = "127.0.0.1";
          Port = config.my.services.qbittorrent.port;
          Username = qbuser;
          Password_PBKDF2 = qbpasswd;
          CSRFProtection = true;
          LocalHostAuth = true;
        };
        General.Locale = "en";
      };

      Queueing.QueueingEnabled = false;
      Bittorrent = {
        SeedingLimitsRatio = -1;
        MaxSeedingTime = -1;
      };
      Scheduler = {
        Enabled = true;
        days = 0;
        start_time = "08:00";
        end_time = "22:00";
      };
      Transfer = {
        AltDownloadLimit = 102400;
        AltUploadLimit = 102400;
        GlobalDownloadLimit = 0;
        GlobalUploadLimit = 0;
      };
    };
  };

  users.users.thinkcentre = {
    isNormalUser = true;
    group = "thinkcentre";
  };
  users.groups.thinkcentre = {};
}
