{pkgs, ...}: {
  networking.firewall.allowedTCPPorts = [8686 5030];

  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-music"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  containers.music = {
    additionalCapabilities = [
      "CAP_SYS_ADMIN"
      "CAP_NET_ADMIN"
      "CAP_MKNOD"
      "CAP_BPF"
      "CAP_PERFMON"
    ];
    extraFlags = [
      "--system-call-filter=@keyring"
      "--system-call-filter=@bpf"
      "--system-call-filter=@mount"
      "--system-call-filter=@system-service"
    ];
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.60.10";
    localAddress = "192.168.60.11";

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

    bindMounts = {
      "/data" = {
        hostPath = "/data";
        isReadOnly = false;
      };
      "/etc/slskd.env" = {
        hostPath = "/run/agenix/slskd";
        isReadOnly = true;
      };
    };

    config = {
      config,
      pkgs,
      ...
    }: {
      system.stateVersion = "25.11";

      virtualisation.docker.enable = true;
      virtualisation.oci-containers.backend = "docker";

      services.lidarr = {
        enable = true;
        openFirewall = true;
        user = "root";
        group = "root";
      };

      services.slskd = {
        domain = "127.0.0.1";
        enable = true;
        openFirewall = true;
        user = "root";
        group = "root";
        environmentFile = "/etc/slskd.env";

        settings = {
          directories = {
            downloads = "/data/slskd/downloads";
            incomplete = "/data/slskd/incomplete";
          };
          shares = {
            directories = ["/data/Media/Music"];
          };
          flags = {
            no_version_check = true;
          };
        };
      };

      virtualisation.oci-containers.containers."soularr" = {
        image = "mrusse08/soularr:latest";
        extraOptions = ["--network=host"];
        environment = {
          TZ = "Europe/Rome";
          SCRIPT_INTERVAL = "15";
        };
        volumes = [
          "/var/lib/soularr:/data"
          "/data/slskd/downloads:/downloads"
        ];
      };
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [8686 5030];
      };

      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";

      systemd.tmpfiles.rules = [
        "d /var/lib/soularr 0755 root root -"
        "d /data/slskd/downloads 0775 root root -"
        "d /data/slskd/incomplete 0775 root root -"
        "d /data/Media/Music 0775 root root -"
      ];
    };
  };
}
