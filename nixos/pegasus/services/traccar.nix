{
  config,
  pkgs,
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

  containers.traccar = {
    autoStart = true;
    privateNetwork = true;
    inherit hostAddress localAddress;

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
