{config, ...}: {
  imports = [../../../modules/nixos/deemix];

  my.services.deemix = {
    enable = true;
    dataDir = "/var/lib/deemix";
    musicDir = "/data/Media/Music";
    host = "127.0.0.1";
    singleUser = true;
  };
}
