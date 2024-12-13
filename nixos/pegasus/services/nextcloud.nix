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
        package = pkgs.nextcloud30;
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
            url = "https://github.com/pulsejet/memories/releases/download/v7.3.1/memories.tar.gz";
            sha256 = "sha256-tzxeffvwMwthvBRG+/cLCXZkVS32rlf5v7XOKTbGoOo=";
            license = "agpl3Only";
          };
          mail = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/mail/releases/download/v3.7.1/mail-v3.7.1.tar.gz";
            sha256 = "sha256-hmIWE1Z8NqTAqnNPryGf6r0tL+XA4wARil5rCOglEuI=";
            license = "agpl3Only";
          };
          contacts = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/contacts/releases/download/v6.0.0/contacts-v6.0.0.tar.gz";
            sha256 = "sha256-48ERJ9DQ9w71encT2XVvcVaV+EbthgExQliKO1sQ+1A=";
            license = "agpl3Only";
          };
          extract = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/PaulLereverend/NextcloudExtract/releases/download/1.3.6/extract.tar.gz";
            sha256 = "sha256-y1NacOWnCd/f5sOeEOLeZrWnqwi8q/XezOrhT7AzV/o=";
            license = "agpl3Only";
          };
          news = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud/news/releases/download/25.0.0-alpha8/news.tar.gz";
            sha256 = "sha256-nj1yR2COwQ6ZqZ1/8v9csb/dipXMa61e45XQmA5WPwg=";
            license = "agpl3Only";
          };
          notes = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/notes/releases/download/v4.10.0/notes-v4.10.0.tar.gz";
            sha256 = "sha256-ZSXmot6OmD45dDIUEa6as42OGG3jrXyHWtx+hXzDXRc=";
            license = "agpl3Only";
          };
          epubview = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/devnoname120/epubviewer/releases/download/1.6.3/epubviewer-1.6.3.tar.gz";
            sha256 = "sha256-No4nS1l1J2HMMFiMRaWd3BbgND240UBrWzzg+6xGMqA=";
            license = "agpl3Only";
          };
          phonetrack = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/julien-nc/phonetrack/releases/download/v0.8.1/phonetrack-0.8.1.tar.gz";
            sha256 = "sha256-zQt+3t86HZJVT/wiETHkPdTwV6Qy+iNkH3/THtTe1Xs=";
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
