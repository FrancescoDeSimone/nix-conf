{ config, pkgs, ... }:

{
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-+"];
    externalInterface = "enp1s0";
    enableIPv6 = true;
  };

  containers.nextcloud = {
    bindMounts = {
      "/nextcloud" =
      {
        hostPath ="/nextcloud";
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
    { protocol = "tcp"; hostPort = 8010; containerPort = 80; }
    ];

    config = { config, pkgs, ... }: {
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "nextcloud" ];
        ensureUsers = [
        {
          name = "nextcloud";
          ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
        }
        ];
      };
      services.nextcloud = {
        enable = true;
        https = true;
        home = "/nextcloud";
        package = pkgs.nextcloud27;
        hostName = "nextcloud.desimedia.duckdns.org";
        extraAppsEnable = true;
        configureRedis = true;
        extraApps = {
          deck = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/deck/releases/download/v1.10.0/deck-v1.10.0.tar.gz";
            sha256 = "sha256-8HavzNtdyzc4TDyxsuG8V4uew3VfeQon0FLbx51HRe4=";
          };
          memories = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/pulsejet/memories/releases/download/v5.2.1/memories.tar.gz";
            sha256 = "sha256-NGss+UBvwtDI73CLMc0gdVLCTp0YnNSeWzv/U6yD4mw=";
          };
          richdocuments = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/richdocuments/releases/download/v8.1.1/richdocuments-v8.1.1.tar.gz";
            sha256 = "sha256-SkKEviqtq9823T7i2R6Fe8lLJFPxJgfxLMu6kTe8XRw=";
          };
          mail = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/mail/releases/download/v1.14.1/mail-v1.14.1.tar.gz";
            sha256 = "sha256-sQUsYC3cco6fj9pF2l1NrCEhA3KJoOvJRhXvBlVpNqo=";
          };
          contacts = pkgs.fetchNextcloudApp rec {
            url = "https://github.com/nextcloud-releases/contacts/releases/download/v4.2.2/contacts-v4.2.2.tar.gz";
            sha256 = "sha256-eTc51pkg3OdHJB7X4/hD39Ce+9vKzw1nlJ7BhPOzdy0=";
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
        requires = [ "postgresql.service" ];
        after = [ "postgresql.service" ];
      };

      system.stateVersion = "23.05";

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 80 443];
      };

      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };

}
