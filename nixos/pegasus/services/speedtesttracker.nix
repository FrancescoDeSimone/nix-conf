{...}: {
  imports = [../../../modules/nixos/speedtest-tracker];

  my.services.speedtest-tracker = {
    enable = true;
    database = "sqlite";
    appURL = "http://speedtracker.pegasus.lan";
    prometheus.enable = true;
    schedule = "0 * * * *";
  };
}
