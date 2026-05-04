{ common }:
{
  "adguard-home.json" = import ./adguard.nix { inherit common; };
  "arr-stack.json" = import ./arr-stack.nix { inherit common; };
  "bot-activity.json" = import ./bot-activity.nix { inherit common; };
  "fail2ban.json" = import ./fail2ban.nix { inherit common; };
  "nginx-traffic.json" = import ./nginx.nix { inherit common; };
  "service-health.json" = import ./service-health.nix { inherit common; };
  "speedtest-tracker.json" = import ./speedtest.nix { inherit common; };
  "system.json" = import ./system.nix { inherit common; };
  "tailnet-overview.json" = import ./tailnet.nix { inherit common; };
}
