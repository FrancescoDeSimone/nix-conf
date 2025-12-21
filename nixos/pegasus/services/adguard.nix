{
  containers.adguard = {
    autoStart = true;
    privateNetwork = true;
    macvlan = [ "eno1" ];
    hostAddress = "192.168.50.10";
    localAddress = "192.168.50.12";
    forwardPorts = [
      {
        protocol = "tcp";
        hostPort = 3000;
        containerPort = 3000;
      }
    ];
    config =
      { config
      , pkgs
      , ...
      }: {
        services.adguardhome = {
          enable = true;
          openFirewall = true;
          allowDHCP = false;
          settings = {
            schema_version = 20;
            dns = {
              ratelimit = 0;
              bind_hosts = [ "0.0.0.0" ];
              upstream_dns = [
                "1.1.1.1"
                "1.0.0.1"
                "8.8.8.8"
                "8.8.4.4"
              ];
            };
          };
        };
        system.stateVersion = "24.11";
        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ 3000 ];
        };
        environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
      };
  };
}
