{ config, pkgs, ... }:

{
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  containers.git = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.200.10";
    localAddress = "192.168.200.11";
    forwardPorts = [
      {
        protocol = "tcp";
        hostPort = 3000;
        containerPort = 3000;
      }
      {
        protocol = "tcp";
        hostPort = 3001;
        containerPort = 3001;
      }
    ];

    config = { config, pkgs, ... }: {
      services.postgresql = {
        enable = true;
        # ensureDatabases = [ "gogs" "gitea" ];
        ensureDatabases = [ "gitea" ];
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser  auth-method
          local all       all     trust
          host all        all  127.0.0.1/32   trust
        '';
        ensureUsers = [
          # {
          #   name = "gogs";
          #   ensureDBOwnership = true;
          # }
          {
            name = "gitea";
            ensureDBOwnership = true;
          }
        ];
      };

      # services.gogs = {
      #   enable = true;
      #   database = {
      #     type = "postgres";
      #     port = 5432;
      #   };
      # };

      services.gitea = {
        enable = true;
        database = { type = "postgres"; };
        settings.server = {
          HTTP_ADDR = "0.0.0.0";
          HTTP_PORT = 3001;
        };
      };

      systemd.services."gitea" = {
        requires = [ "postgresql.service" ];
        after = [ "postgresql.service" ];
      };

      # systemd.services."gogs" = {
      #   requires = [ "postgresql.service" ];
      #   after = [ "postgresql.service" ];
      # };

      system.stateVersion = "24.05";

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 3000 3001 ];
      };

      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };

}
