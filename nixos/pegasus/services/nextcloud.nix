{
  config,
  private,
  lib,
  ...
}: let
  domain = private.nginx.domain;
  duplicatiPort = config.my.services.duplicati.port;
  duplicatiPasswordExists = builtins.pathExists ../../../secrets/duplicati-password.age;
in {
  age.secrets = lib.optionalAttrs duplicatiPasswordExists {
    "duplicati-password" = {
      file = ../../../secrets/duplicati-password.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-nextcloud"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  containers.nextcloud = {
    bindMounts =
      {
        "/nextcloud" = {
          hostPath = "/nextcloud";
          isReadOnly = false;
        };
      }
      // lib.optionalAttrs duplicatiPasswordExists {
        "/run/duplicati-password" = {
          hostPath = config.age.secrets."duplicati-password".path;
          isReadOnly = true;
        };
      };
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
    hostAddress6 = "fc00::1";
    localAddress6 = "fc00::2";
    forwardPorts = [
      {
        protocol = "tcp";
        hostPort = config.my.services.nextcloud.port;
        containerPort = 80;
      }
    ];
    config = {pkgs, ...}: {
      services.postgresql = {
        package = pkgs.postgresql_14;
        enable = true;
        ensureDatabases = ["nextcloud"];
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser  auth-method
          local all       all     trust
          host all        all  127.0.0.1/32   trust
        '';
        ensureUsers = [
          {
            name = "nextcloud";
            ensureDBOwnership = true;
          }
        ];
      };

      services.duplicati =
        {
          enable = true;
          interface = "any";
          user = "root";
          port = duplicatiPort;
          parameters = ''
            --webservice-allowedhostnames=duplicati.${private.nginx.internalDomain}
          '';
        }
        // lib.optionalAttrs duplicatiPasswordExists {
          serverPasswordFile = "/run/duplicati-password";
        };

      # services.paperless = {
      #   enable = true;
      #   address = "0.0.0.0";
      # };

      services.nextcloud = {
        phpOptions = {
          "memory_limit" = lib.mkForce "2G";
        };
        enable = true;
        https = true;
        home = "/nextcloud";
        package = pkgs.nextcloud35;
        hostName = "nextcloud." + domain;
        extraAppsEnable = true;
        configureRedis = true;
        extraApps = {
          deck = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/deck/releases/download/v1.19.1/deck-v1.19.1.tar.gz";
            sha256 = "sha256-OC4RE57jmURL36F/AYqpEJN2ko+b02CQ6tjqNAtNPw4";
            license = "agpl3Only";
          };
          memories = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/pulsejet/memories/releases/download/v10.2.0/memories.tar.gz";
            sha256 = "sha256-MBY1eCtCDPwpuXOdBM/YUNTK5OMDpufFZELxbdSvxRQ";
            license = "agpl3Only";
          };
          mail = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/mail/releases/download/v5.12.5/mail-v5.12.5.tar.gz";
            sha256 = "sha256-xS2rGKTeFxCFQDjZWBD5rk63aoZW2JgA59zrWv8ANOA";
            license = "agpl3Only";
          };
          contacts = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/contacts/releases/download/v8.9.2/contacts-v8.9.2.tar.gz";
            sha256 = "sha256-kvfHnEEScwRe1jRvaYjAWvZzwxcKOtq6kaFQZrjc58U";
            license = "agpl3Only";
          };
          # extract app dropped: dead upstream since 2023, max supported Nextcloud 27.
          news = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud/news/releases/download/29.0.0/news.tar.gz";
            sha256 = "sha256-5R1ADlcStdxl00masnUuifA8UPfPyiXO3g6B25LEuJo";
            license = "agpl3Only";
          };
          notes = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/notes/releases/download/v6.1.0/notes-v6.1.0.tar.gz";
            sha256 = "sha256-A8ST9FyxelAFoNzpHE5ZspTvkdRSDD70SiHV5h5BlSY";
            license = "agpl3Only";
          };
          epubview = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/devnoname120/epubviewer/releases/download/1.9.17/epubviewer-1.9.17.tar.gz";
            sha256 = "sha256-cN8CW7122zpfiqJgKJK6q8oKvKszq2t/5KCWtmkOxTc";
            license = "agpl3Only";
          };
          phonetrack = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/julien-nc/phonetrack/releases/download/v1.4.1/phonetrack-1.4.1.tar.gz";
            sha256 = "sha256-56GuG9yhL7vSOX8dESjIkH4hSeZNAO6Oi+WmY2zWxXY=";
            license = "agpl3Only";
          };
        };
        config = {
          dbtype = "pgsql";
          dbuser = "nextcloud";
          dbhost = "/run/postgresql";
          dbname = "nextcloud";
          adminuser = "desi";
          adminpassFile = "/var/lib/nextcloud/adminpass";
        };
      };

      systemd.services."nextcloud-setup" = {
        requires = ["postgresql.service"];
        after = ["postgresql.service"];
      };

      system.stateVersion = "24.11";

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [80 443 duplicatiPort];
      };

      networking.resolvconf.enable = false;
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };
}
