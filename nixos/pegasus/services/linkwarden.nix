{
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-git"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };
  containers.linkwarden = {
    autoStart = true;
    privateNetwork = false;
    hostAddress = "192.168.200.10";
    localAddress = "192.168.200.12";
    specialArgs = {system-call-filter = "add_key bpf keyctl";};
    forwardPorts = [
      {
        protocol = "tcp";
        hostPort = 3000;
        containerPort = 3000;
      }
    ];

    config = {
      config,
      pkgs,
      lib,
      ...
    }: {
      virtualisation = {
        podman = {
          enable = true;
          # autoPrune.enable = true;
          # rootless = {
          #   enable = true;
          #   setSocketVariable = true;
          # };
        };
        oci-containers = {
          backend = "podman";
          containers."linkwarden" = {
            image = "ghcr.io/linkwarden/linkwarden:latest";
            extraOptions = ["--network=host"];
            environment = {
              "DATABASE_URL" = "postgresql://postgres:linkwarden@127.0.0.1:5432/postgres";
              "NEXTAUTH_SECRET" = "lolztest";
              "NEXTAUTH_URL" = "http://0.0.0.0:3000/api/v1/auth";
              "NEXT_PUBLIC_OLLAMA_ENDPOINT_URL" = "http://0.0.0.0:11434";
              "OLLAMA_MODEL" = "phi3:mini-4k";
            };
            volumes = [
              "./linkwarden/data:/data/data:rw"
            ];
          };
        };
      };
      services.ollama = {
        enable = true;
        acceleration = "rocm";
        openFirewall = true;
      };

      services.postgresql = {
        ensureDatabases = ["linkwarden"];
        enable = true;
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser  auth-method
          local all       all     trust
          host all        all  127.0.0.1/32   trust
        '';
        ensureUsers = [
          {
            name = "linkwarden";
            ensureDBOwnership = true;
          }
        ];
      };
      system.stateVersion = "24.11";

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [3000];
      };

      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };
}
