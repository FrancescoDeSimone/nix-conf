{ config, pkgs, ... }:

{
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "enp1s0";
    enableIPv6 = true;
  };

  containers.gogs = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.200.10";
    localAddress = "192.168.200.11";
    forwardPorts = [
      { protocol = "tcp"; hostPort = 3000; containerPort = 3000; }
    ];

    config = { config, pkgs, ... }: {
      services.postgresql = {
        enable = true;
        port = 3306;
        ensureDatabases = [ "gogs" ];
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser  auth-method
          local all       all     trust
          host all        all  127.0.0.1/32   trust
        '';
        ensureUsers = [
          {
            name = "gogs";
            ensureDBOwnership = true;
          }
        ];
      };

      services.gogs = {
        enable = true;
        database = {
          type = "postgres";
        };
      };

      systemd.services."gogs" = {
        requires = [ "postgresql.service" ];
        after = [ "postgresql.service" ];
      };

      system.stateVersion = "23.11";

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 3000 ];
      };

      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };

}
