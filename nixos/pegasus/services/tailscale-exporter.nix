{
  config,
  pkgs,
  ...
}: {
  users.groups.tailscale-exporter = {};

  users.users.tailscale-exporter = {
    isSystemUser = true;
    group = "tailscale-exporter";
    description = "Tailscale Prometheus Exporter";
  };

  systemd.services.tailscale-exporter = {
    description = "Prometheus exporter for Tailscale metrics";
    after = [
      "network.target"
      "headscale.service"
    ];
    requires = ["headscale.service"];
    wantedBy = ["multi-user.target"];

    script = ''
      export HEADSCALE_API_KEY="$(< ${config.age.secrets."tailscale-exporter-api-key".path})"

      exec ${pkgs.unstable.prometheus-tailscale-exporter}/bin/tailscale-exporter \
        --headscale-address=127.0.0.1:50443 \
        --headscale-api-key="$HEADSCALE_API_KEY" \
        --headscale-insecure \
        --listen-address=127.0.0.1:${toString config.my.services.tailscale-exporter.port}
    '';

    serviceConfig = {
      Type = "simple";

      User = "tailscale-exporter";
      Group = "tailscale-exporter";

      Restart = "on-failure";
      RestartSec = "10s";

      # Hardening (optional but sensible)
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };
}
