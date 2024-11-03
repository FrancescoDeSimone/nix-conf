{lib, ...}: {
  systemd.services.transmission.serviceConfig.Restart = lib.mkForce "always";
  services.transmission = {
    enable = true;
    openRPCPort = true;
    openFirewall = true;
    user = "thinkcentre";
    settings = {
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist-enabled = false;
      home = "/data/transmission";
      download-dir = "/data/transmission/Downloads";
      incomplete-dir = "/data/transmission/.incomplete";
      watch-dir = "/data/transmission/watchdir";
      alt-speed-time-enabled = true;
      alt-speed-time-end = 1410;
    };
  };
}
