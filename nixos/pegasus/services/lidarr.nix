{
  private,
  pkgs,
  ...
}: {
  # 1. Open ports on the HOST (Pegasus) so you can access them from your LAN
  networking.firewall.allowedTCPPorts = [8686 5030];

  # 2. Setup NAT for the container
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-music"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  containers.music = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.60.10";
    localAddress = "192.168.60.11";

    # 3. Forward ports: Host Port -> Container Port
    forwardPorts = [
      {
        protocol = "tcp";
        hostPort = 8686;
        containerPort = 8686;
      } # Lidarr
      {
        protocol = "tcp";
        hostPort = 5030;
        containerPort = 5030;
      } # Slskd
    ];

    # 4. Mount your data pool
    bindMounts = {
      "/data" = {
        hostPath = "/data";
        isReadOnly = false;
      };
    };

    config = {
      config,
      pkgs,
      ...
    }: {
      system.stateVersion = "25.05";

      # --- Docker (For Soularr) ---
      virtualisation.docker.enable = true;
      virtualisation.oci-containers.backend = "docker";

      # --- Lidarr (Native) ---
      services.lidarr = {
        enable = true;
        package = pkgs.unstable.lidarr;
        openFirewall = true;
        # Run as root inside container to ensure write access to /data/Media/Music
        user = "root";
        group = "root";
      };

      # --- Slskd (Native) ---
      services.slskd = {
        enable = true;
        package = pkgs.unstable.slskd;
        openFirewall = true;
        user = "root";
        group = "root";

        settings = {
          directories = {
            downloads = "/data/slskd/downloads";
            incomplete = "/data/slskd/incomplete";
          };
          shares = {
            # Optional: Lets you share your music with the Soulseek network
            directories = ["/data/Media/Music"];
          };
          flags = {
            no_version_check = true;
          };
        };
      };

      # --- Soularr (Docker inside Container) ---
      virtualisation.oci-containers.containers."soularr" = {
        image = "mrusse08/soularr:latest";
        # Host networking lets it talk to localhost:8686 (Lidarr) and localhost:5030 (Slskd)
        extraOptions = ["--network=host"];
        environment = {
          TZ = "Europe/Rome";
          SCRIPT_INTERVAL = "300";
        };
        volumes = [
          "/var/lib/soularr:/data" # Config file location
          "/data/slskd/downloads:/downloads" # Must match Slskd download path
        ];
      };

      # Allow local traffic inside the container
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [8686 5030];
      };

      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";

      # Ensure directories exist
      systemd.tmpfiles.rules = [
        "d /var/lib/soularr 0755 root root -"
        "d /data/slskd/downloads 0775 root root -"
        "d /data/slskd/incomplete 0775 root root -"
        # Ensure Lidarr can see the music folder if it doesn't exist (it exists on host, but good practice)
        "d /data/Media/Music 0775 root root -"
      ];
    };
  };
}
