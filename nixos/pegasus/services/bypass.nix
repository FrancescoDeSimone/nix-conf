{
  config,
  pkgs,
  ...
}: {
  systemd.services.bypass = {
    description = "13ft bypass service";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = "${pkgs."13ft"}/bin/13ft";
      Environment = [
        "THIRTEENFT_HOST=127.0.0.1"
        "THIRTEENFT_PORT=${toString config.my.services.bypass.port}"
      ];
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
