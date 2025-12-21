{
  pkgs,
  lib,
  config,
  ...
}: {
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-govd"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  containers.govd = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.70.10";
    localAddress = "192.168.70.11";

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

    bindMounts = {
      "/run/agenix/govd" = {
        hostPath = "/run/agenix/govd";
        isReadOnly = true;
      };
    };

    config = {pkgs, ...}: {
      system.stateVersion = "25.11";

      virtualisation.docker = {
        enable = true;
        autoPrune.enable = true;
      };
      virtualisation.oci-containers.backend = "docker";

      systemd.services."docker-network-govd" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "docker network rm -f govd-network";
        };
        script = ''
          docker network inspect govd-network || docker network create govd-network --driver=bridge
        '';
        partOf = ["docker-compose-govd-root.target"];
        wantedBy = ["docker-compose-govd-root.target"];
      };

      virtualisation.oci-containers.containers."db" = {
        image = "postgres:latest";
        environment = {
          "POSTGRES_DB" = "govd";
          "POSTGRES_USER" = "govd";
          "PGDATA" = "/var/lib/postgresql/data/pgdata";
        };
        environmentFiles = ["/run/agenix/govd"];
        volumes = [
          "govd_db:/var/lib/postgresql/data:rw"
        ];
        log-driver = "journald";
        extraOptions = [
          "--health-cmd=pg_isready -U govd"
          "--health-interval=3s"
          "--health-retries=30"
          "--health-timeout=5s"
          "--network-alias=db"
          "--network=govd-network"
        ];
      };

      systemd.services."docker-db" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };
        after = ["docker-network-govd.service" "docker-volume-govd_db.service"];
        requires = ["docker-network-govd.service" "docker-volume-govd_db.service"];
        partOf = ["docker-compose-govd-root.target"];
        wantedBy = ["docker-compose-govd-root.target"];
      };

      virtualisation.oci-containers.containers."bot" = {
        image = "govdbot/govd:main";
        environmentFiles = ["/run/agenix/govd"];
        volumes = [
          "/var/lib/govd/downloads:/app/downloads:rw"
          "/var/lib/govd/logs:/app/logs:rw"
          "/var/lib/govd/private:/app/private:rw"
        ];
        ports = [
          "127.0.0.1:8080:8080"
          "127.0.0.1:6060:6060"
        ];
        dependsOn = ["db"];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=bot"
          "--network=govd-network"
        ];
      };

      systemd.services."docker-bot" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };
        after = ["docker-network-govd.service" "docker-db.service"];
        requires = ["docker-network-govd.service" "docker-db.service"];
        partOf = ["docker-compose-govd-root.target"];
        wantedBy = ["docker-compose-govd-root.target"];
      };

      systemd.services."docker-volume-govd_db" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect govd_db || docker volume create govd_db
        '';
        partOf = ["docker-compose-govd-root.target"];
        wantedBy = ["docker-compose-govd-root.target"];
      };

      systemd.targets."docker-compose-govd-root" = {
        unitConfig = {Description = "Root target for govd stack";};
        wantedBy = ["multi-user.target"];
      };

      systemd.services.govd-cleanup = {
        description = "Cleanup govd data";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash -c 'rm -rf /var/lib/govd/downloads/* /var/lib/govd/logs/*'";
        };
      };
      systemd.timers.govd-cleanup = {
        description = "Run govd cleanup daily";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/govd/downloads 0755 root root -"
        "d /var/lib/govd/logs 0755 root root -"
        "d /var/lib/govd/private 0755 root root -"
      ];

      networking.firewall.enable = true;
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };
}
