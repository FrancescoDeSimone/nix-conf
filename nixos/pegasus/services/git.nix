{
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-git" ];
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
        hostPort = 3001;
        containerPort = 3001;
      }
    ];

    config =
      { config
      , pkgs
      , ...
      }: {
        services.postgresql = {
          enable = true;
          package = pkgs.postgresql_15;
          ensureDatabases = [ "gitea" ];
          authentication = pkgs.lib.mkOverride 10 ''
            #type database  DBuser  auth-method
            local all       all     trust
            host all        all  127.0.0.1/32   trust
          '';
          ensureUsers = [
            {
              name = "gitea";
              ensureDBOwnership = true;
            }
          ];
        };

        services.gitea = {
          enable = true;
          database = { type = "postgres"; };
          settings = {
            indexer = {
              REPO_INDEXER_ENABLED = true;
              REPO_INDEXER_PATH = "indexers/repos.bleve";
              REPO_INDEXER_EXCLUDE = "resources/bin/**";
            };
            migrations = {
              ALLOWED_DOMAINS = "*";
              ALLOW_LOCALNETWORKS = true;
              SKIP_TLS_VERIFY = true;
            };
            service.DISABLE_REGISTRATION = true;
            server = {
              HTTP_ADDR = "0.0.0.0";
              HTTP_PORT = 3001;
            };
          };
        };

        systemd.services."gitea" = {
          requires = [ "postgresql.service" ];
          after = [ "postgresql.service" ];
        };

        system.stateVersion = "24.11";

        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ 3001 ];
        };

        environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
      };
  };
}
