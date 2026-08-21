{...}: {
  catppuccin.gitea = {
    enable = true;
    flavor = "mocha";
  };

  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-git"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  # services.gitea-actions-runner = {
  #   package = pkgs.gitea-actions-runner;
  #   instances."pegasus-runner" = {
  #     enable = true;
  #     url = "http://192.168.200.10:3001";
  #     name = "pegasus-runner";
  #     labels = ["linux" "x64"];
  #     # TODO: add agenix secret for token
  #   };
  # };

  containers.git = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.200.10";
    localAddress = "192.168.200.11";

    config = {pkgs, ...}: {
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_15;
        ensureDatabases = ["gitea"];
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
        database = {type = "postgres";};
        settings = {
          indexer = {
            REPO_INDEXER_ENABLED = true;
            REPO_INDEXER_PATH = "indexers/repos.bleve";
            REPO_INDEXER_EXCLUDE = "resources/bin/**";
          };
          migrations = {
            ALLOWED_DOMAINS = "github.com,gitlab.com,codeberg.org,git.sr.ht,bitbucket.org";
            ALLOW_LOCALNETWORKS = false;
            SKIP_TLS_VERIFY = false;
          };
          webhook = {
            ALLOWED_HOST_LIST = "github.com,gitlab.com,codeberg.org,git.sr.ht,bitbucket.org";
          };
          service.DISABLE_REGISTRATION = true;
          server = {
            HTTP_ADDR = "0.0.0.0";
            HTTP_PORT = 3001;
          };
        };
      };

      systemd.services."gitea" = {
        requires = ["postgresql.service"];
        after = ["postgresql.service"];
      };

      system.stateVersion = "24.11";

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [3001];
      };

      networking.resolvconf.enable = false;
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };
}
