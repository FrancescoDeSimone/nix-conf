{config, ...}: {
  containers.adguard = {
    autoStart = true;
    privateNetwork = true;
    macvlans = ["eno1"];
    forwardPorts = [
      {
        protocol = "tcp";
        hostPort = config.my.services.adguard.port;
        containerPort = 3000;
      }
    ];
    config = {
      config,
      ...
    }: {
      networking.useHostResolvConf = false;
      networking.nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4"];
      networking.useNetworkd = true;
      systemd.network.networks."10-adguard-lan" = {
        matchConfig.Name = "mv-eno1";
        address = ["192.168.188.2/24"];
        routes = [
          {
            Destination = "0.0.0.0/0";
            Gateway = "192.168.188.1";
          }
        ];
      };

      services.adguardhome = {
        enable = true;
        openFirewall = false;
        mutableSettings = false;
        allowDHCP = true;
        host = "0.0.0.0";
        port = 3000;
        settings = {
          schema_version = 28;
          dns = {
            ratelimit = 0;
            bind_hosts = ["192.168.188.2"];
            bootstrap_dns = ["1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4"];
            upstream_dns = ["1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4"];
            local_domain_name = "lan";
          };
          filtering = {
            protection_enabled = true;
            filtering_enabled = true;
          };
          querylog.enabled = true;
          statistics.enabled = true;
          dhcp = {
            enabled = true;
            interface_name = "mv-eno1";
            dhcpv4 = {
              gateway_ip = "192.168.188.1";
              subnet_mask = "255.255.255.0";
              range_start = "192.168.188.100";
              range_end = "192.168.188.199";
              lease_duration = 86400;
            };
          };
        };
      };

      system.stateVersion = "24.11";
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [53 3000];
        allowedUDPPorts = [53 67];
      };
    };
  };
}
