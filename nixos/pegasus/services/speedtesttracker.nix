{
  private,
  ...
}: {
  imports = [../../../modules/nixos/speedtest-tracker];

  my.services.speedtest-tracker = {
    enable = true;
    database = "sqlite";
    appURL = "https://speedtracker.${private.nginx.internalDomain}";
    prometheus.enable = true;
    schedule = "0 * * * *";
  };
}
