{private, ...}: let
  domain = private.nginx.domain;
in {
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-nextcloud"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  containers.nextcloud = {
    bindMounts = {
      "/nextcloud" = {
        hostPath = "/nextcloud";
        isReadOnly = false;
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
        hostPort = 8010;
        containerPort = 80;
      }
      {
        protocol = "tcp";
        hostPort = 8200;
        containerPort = 8200;
      }
      {
        protocol = "tcp";
        hostPort = 28981;
        containerPort = 28981;
      }
    ];
    config = {
      config,
      pkgs,
      ...
    }: {
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

      services.duplicati = {
        enable = true;
        interface = "any";
        user = "root";
      };

      # services.paperless = {
      #   enable = true;
      #   address = "0.0.0.0";
      # };

      services.nextcloud = {
        enable = true;
        https = true;
        home = "/nextcloud";
        package = pkgs.nextcloud32;
        hostName = "nextcloud." + domain;
        extraAppsEnable = true;
        configureRedis = true;
        extraApps = {
          deck = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/deck/releases/download/v1.13.0/deck-v1.13.0.tar.gz";
            sha256 = "sha256-Gyfyq4rJv4alLhdIW8S8wCUAOdxp6UG7UgUWH0CkVR4=";
            license = "agpl3Only";
          };
          memories = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/pulsejet/memories/releases/download/v7.7.0/memories.tar.gz";
            sha256 = "sha256-ORv+6XkN+qTk5bXMFKv2Mv/jU+7F12IbWE9JjV2ot9o=";
            license = "agpl3Only";
          };
          mail = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/mail/releases/download/v3.7.1/mail-v3.7.1.tar.gz";
            sha256 = "sha256-hmIWE1Z8NqTAqnNPryGf6r0tL+XA4wARil5rCOglEuI=";
            license = "agpl3Only";
          };
          contacts = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/contacts/releases/download/v8.1.0/contacts-v8.1.0.tar.gz";
            sha256 = "sha256-kQ6OunNZbj0UjDinkDhj2ZYDeoEWqvAvgpHDDTFdlW8=";
            license = "agpl3Only";
          };
          extract = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/PaulLereverend/NextcloudExtract/releases/download/1.3.6/extract.tar.gz";
            sha256 = "sha256-y1NacOWnCd/f5sOeEOLeZrWnqwi8q/XezOrhT7AzV/o=";
            license = "agpl3Only";
          };
          news = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud/news/releases/download/28.0.0-beta.1/news.tar.gz";
            sha256 = "sha256-52P1o2b5RIuSXaCMl6Fk6336J8zNtEd6JivGnQbGZc4=";
            license = "agpl3Only";
          };
          notes = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/notes/releases/download/v4.12.4/notes-v4.12.4.tar.gz";
            sha256 = "sha256-iiNXIvq+rUbbecU646pyRpHP0EjUdQT1ybKMS2JQbwc=";
            license = "agpl3Only";
          };
          epubview = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/devnoname120/epubviewer/releases/download/1.8.1/epubviewer-1.8.1.tar.gz";
            sha256 = "sha256-0AYCutDNvCfwul+VIh+g7FkD8LJVmd0ZNSZHDcpdU3I=";
            license = "agpl3Only";
          };
          phonetrack = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/julien-nc/phonetrack/releases/download/v0.9.1/phonetrack-0.9.1.tar.gz";
            sha256 = "sha256-Le3yvewei8vty8frz66X7ij2H9ju2h4JWdGNf46L9MY=";
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
        allowedTCPPorts = [80 443 8200 28981];
      };

      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };
}
