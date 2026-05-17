{
  pkgs,
  config,
  ...
}: let
  scrutinyApi = "http://127.0.0.1:${toString config.my.services.scrutiny.port}";
  exporterPort = 9900;
in {
  services.scrutiny = {
    enable = true;
    settings = {
      web.listen.port = config.my.services.scrutiny.port;
    };
    openFirewall = false;
  };

  services.scrutiny.collector = {
    enable = true;
    settings = {
      api.endpoint = scrutinyApi;
      host.id = "pegasus";
    };
  };

  systemd.services.scrutiny-exporter = {
    description = "Scrutiny Prometheus metrics exporter";
    after = ["scrutiny.service"];
    wants = ["scrutiny.service"];
    wantedBy = ["multi-user.target"];
    environment = {
      SCRUTINY_API_URL = scrutinyApi;
      EXPORTER_PORT = toString exporterPort;
      CACHE_DURATION = "120";
      LOG_LEVEL = "INFO";
    };
    serviceConfig = {
      ExecStart = "${pkgs.python3.withPackages (ps: [ps.prometheus-client ps.requests])}/bin/python3 ${./scrutiny-exporter.py}";
      Restart = "always";
      RestartSec = "5";
      DynamicUser = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  networking.firewall.allowedTCPPorts = [exporterPort];
}
