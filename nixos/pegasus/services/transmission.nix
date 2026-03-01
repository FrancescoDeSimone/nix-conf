{ lib, ... }: {
  systemd.services.transmission.serviceConfig.Restart = lib.mkForce "always";
  services.transmission = {
    enable = true;
    openRPCPort = true;
    openFirewall = false;
    user = "thinkcentre";
    settings = {
      rpc-bind-address = "127.0.0.1";
      rpc-whitelist-enabled = true;
      rpc-whitelist = [ "127.0.0.1" ];
      home = "/data/transmission";
      download-dir = "/data/transmission/Downloads";
      incomplete-dir = "/data/transmission/.incomplete";
      watch-dir = "/data/transmission/watchdir";
      alt-speed-time-enabled = true;
      alt-speed-time-end = 1410;
    };
  };
}
