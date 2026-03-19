{
  pkgs,
  config,
  ...
}: {
  systemd.services.byparr = {
    description = "Byparr API Service";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    environment = {
      PORT = toString config.my.services.byparr.port;
    };
    serviceConfig = {
      ExecStart = "${pkgs.byparr}/bin/byparr";
      Restart = "always";
      RestartSec = "3"; # Give it a few seconds before restarting
      DynamicUser = true;
      StateDirectory = "byparr"; # Provides persistent /var/lib/byparr
      CacheDirectory = "byparr"; # Provides persistent /var/cache/byparr
    };
  };
}
