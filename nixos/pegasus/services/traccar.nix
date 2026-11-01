{
  config,
  ...
}: let
  traccarPort = config.my.services.traccar.port;
  owntracksPort = config.my.services.owntracks.port;
  hostAddress = "192.168.101.10";
  localAddress = "192.168.101.11";
in {
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-traccar"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  systemd.tmpfiles.rules = [
    # Only the daily db dumps need host visibility (for duplicati). Traccar's
    # own StateDirectory (/var/lib/traccar) is managed by systemd inside the
    # container and holds just config.xml — fully regenerated at boot — so it
    # must NOT be a bind mount (DynamicUser tries to move it and fails on a
    # mounted path).
    "d /var/lib/traccar-dumps 0750 root root -"
  ];

  containers.traccar = {
    autoStart = true;
    privateNetwork = true;
    inherit hostAddress localAddress;

    bindMounts."/var/lib/traccar-dumps" = {
      hostPath = "/var/lib/traccar-dumps";
      isReadOnly = false;
    };

    config = {pkgs, ...}: {
      services.postgresql = {
        package = pkgs.postgresql_17;
        enable = true;
        ensureDatabases = ["traccar"];
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser  auth-method
          local all       all     trust
          host all        all  127.0.0.1/32   trust
        '';
        ensureUsers = [
          {
            name = "traccar";
            ensureDBOwnership = true;
          }
        ];
      };

      # OwnTracks ingest (OwnTracks booklet "Traccar"): the app posts JSON in
      # HTTP mode to the owntracks port. The port also accepts plaintext TCP,
      # which never leaves the container. Device secret = a long random
      # `topic` set as the device's unique identifier; nginx additionally
      # checks the URL token path on the public vhost.
      services.traccar = {
        enable = true;
        settings = {
          database = {
            driver = "org.postgresql.Driver";
            url = "jdbc:postgresql://127.0.0.1:5432/traccar";
            user = "traccar";
            password = "";
          };
          owntracks.port = toString owntracksPort;
          web.port = toString traccarPort;
        };
      };

      systemd.services.traccar = {
        requires = ["postgresql.service"];
        after = ["postgresql.service"];
      };

      # Backups: duplicati (opencloud container) reads /var/lib/traccar-dumps
      # (bind-mounted, read-only, on the host). A live dump is the only safe
      # copy of the database — traccar's own StateDirectory stays inside the
      # container.
      systemd.services.traccar-db-dump = {
        description = "Dump Traccar database for backups";
        after = ["postgresql.service"];
        wantedBy = ["timers.target"];
        startAt = "daily";
        script = ''
          set -eu
          dumpDir=/var/lib/traccar-dumps
          mkdir -p "$dumpDir"
          dump="$dumpDir/traccar-$(date +%F).sqlc"
          trap 'rm -f "$dump.tmp"' EXIT
          # Client runs as root but authenticates as the traccar role
          # (pg_hba trust); role root does not exist in this cluster.
          ${pkgs.postgresql_17}/bin/pg_dump --username=traccar --format=custom traccar > "$dump.tmp"
          chmod 0400 "$dump.tmp"
          mv "$dump.tmp" "$dump"
          trap - EXIT
          ls -1t "$dumpDir"/traccar-*.sqlc | tail -n +8 | ${pkgs.coreutils}/bin/xargs -r rm
        '';
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [traccarPort owntracksPort];
      };

      networking.resolvconf.enable = false;
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";

      system.stateVersion = "25.11";
    };
  };
}
