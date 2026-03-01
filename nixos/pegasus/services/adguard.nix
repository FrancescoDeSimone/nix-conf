{ config
, pkgs
, ...
}: {
  containers.adguard = {
    autoStart = true;
    privateNetwork = true;
    macvlan = [ "eno1" ];
    hostAddress = "192.168.50.10";
    localAddress = "192.168.50.12";
    forwardPorts = [
      {
        protocol = "tcp";
        hostPort = config.my.services.adguard.port;
        containerPort = 3000;
      }
      {
        protocol = "tcp";
        hostPort = config.my.services.adguard.exporter;
        containerPort = 9617;
      }
    ];
    config =
      { config
      , pkgs
      , ...
      }: {
        services.adguardhome = {
          enable = true;
          openFirewall = false;
          allowDHCP = false;
          settings = {
            schema_version = 20;
            prometheus = true;
            dns = {
              ratelimit = 0;
              bind_hosts = [ "127.0.0.1" ];
              upstream_dns = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4" ];
            };
          };
        };
        system.stateVersion = "24.11";
        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ 3000 9617 ];
        };
        environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
      };
  };
}
