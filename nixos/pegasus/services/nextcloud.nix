{
  private,
  lib,
  ...
}: let
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
        phpOptions = {
          "memory_limit" = lib.mkForce "2G";
        };
        enable = true;
        https = true;
        home = "/nextcloud";
        package = pkgs.nextcloud33;
        hostName = "nextcloud." + domain;
        extraAppsEnable = true;
        configureRedis = true;
        extraApps = {
          deck = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/deck/releases/download/v1.17.1/deck-v1.17.1.tar.gz";
            sha256 = "sha256-5ayXPoq2E8eIQqL74p/dytqmjAN3vkAZvrgQIqxf7Zo=";
            license = "agpl3Only";
          };
          memories = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/pulsejet/memories/releases/download/v8.0.1/memories.tar.gz";
            sha256 = "sha256-B+O78qjBQbmMnFAvH/5a+YBive+rkBG9AKTX7G3qNR0=";
            license = "agpl3Only";
          };
          mail = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/mail/releases/download/v5.8.1/mail-v5.8.1.tar.gz";
            sha256 = "sha256-0IBTi0JVBBCTLEcSDiB1eMj2B31qeT4Yn9+ogY9iAs0=";
            license = "agpl3Only";
          };
          contacts = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/contacts/releases/download/v8.5.1/contacts-v8.5.1.tar.gz";
            sha256 = "sha256-SyBJBSxNe1JM8l9AHgYy8AQ3v3hlZhEgUiiTb6xCk70=";
            license = "agpl3Only";
          };
          extract = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/PaulLereverend/NextcloudExtract/releases/download/1.3.6/extract.tar.gz";
            sha256 = "sha256-y1NacOWnCd/f5sOeEOLeZrWnqwi8q/XezOrhT7AzV/o=";
            license = "agpl3Only";
          };
          news = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud/news/releases/download/28.4.1/news.tar.gz";
            sha256 = "sha256-e2lledOH4LzB+/nWjL+wsCuJJTi50yNgPDnGVkl7FNk=";
            license = "agpl3Only";
          };
          notes = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/notes/releases/download/v5.0.0/notes-v5.0.0.tar.gz";
            sha256 = "sha256-NCBDtNO6jsqws4BE8sGOnox2xUuODleYodQ5vv6jqEs=";
            license = "agpl3Only";
          };
          epubview = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/devnoname120/epubviewer/releases/download/1.9.2/epubviewer-1.9.2.tar.gz";
            sha256 = "sha256-HQpC0D+Dj5gojIzz+CHUKmUIkxF2qyqoWI787OFbMF8=";
            license = "agpl3Only";
          };
          phonetrack = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/julien-nc/phonetrack/releases/download/v1.2.0/phonetrack-1.2.0.tar.gz";
            sha256 = "sha256-d6vPKCJ1Us0zQIFkIlSQ5cmEgO1zXGtdDniIjfqGh28=";
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

      networking.resolvconf.enable = false;
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };
}
