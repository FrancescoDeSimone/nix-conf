{ private
, config
, ...
}:
let
  qbuser = private.qb.user;
  qbpasswd = private.qb.passwd;
in
{
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

      BitTorrent.Session = {
        BandwidthSchedulerEnabled = true;
        AlternativeGlobalDLSpeedLimit = 102400;
        AlternativeGlobalUPSpeedLimit = 102400;
        GlobalDLSpeedLimit = 0;
        GlobalUPSpeedLimit = 0;
        QueueingSystemEnabled = false;
        GlobalMaxRatio = -1;
        GlobalMaxSeedingMinutes = -1;
      };

      Preferences.Scheduler = {
        days = 0;
        start_time = "08:00";
        end_time = "22:00";
      };
    };
  };

  users.users.thinkcentre = {
    isNormalUser = true;
    group = "thinkcentre";
  };
  users.groups.thinkcentre = { };
}
