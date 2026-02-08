{
  private,
  pkgs,
  inputs,
  lib,
  ...
}: let
  qbuser = private.qb.user;
  qbpasswd = private.qb.passwd;
  qbpasswd_clear = private.qb.passwd_clear;
in {
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/torrent/qui.nix"
  ];

  services.qbittorrent = {
    enable = true;
    user = "thinkcentre";
    group = "thinkcentre";
    profileDir = "/data/qbittorrent";
    openFirewall = true;

    serverConfig = {
      LegalNotice = {
        Accepted = true;
      };

      Preferences = {
        WebUI = {
          Username = qbuser;
          Password_PBKDF2 = qbpasswd;
          CSRFProtection = false;
          LocalHostAuth = false;
        };
        General = {
          Locale = "en";
        };
      };

      Queueing = {
        QueueingEnabled = false;
      };

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
