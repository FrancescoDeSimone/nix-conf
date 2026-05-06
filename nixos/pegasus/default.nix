{inputs, ...}: {
  imports = [
    ../common
    ./hardware.nix
    # ./disks.nix
    ./filesystem.nix
    ./user.nix

    ./applications.nix
    ./services.nix
    ./cron.nix

    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    (inputs.nixpkgs-unstable + "/nixos/modules/services/networking/headplane.nix")
  ];

  networking.hostName = "pegasus";

  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
  };
  security.tpm2.enable = false;

  age.secrets = {
    provider.file = ../../secrets/provider.age;
    slskd.file = ../../secrets/slskd.age;
    hoarder.file = ../../secrets/hoarder.age;
    govd.file = ../../secrets/govd.age;
    qui.file = ../../secrets/qui.age;
    lidarr.file = ../../secrets/lidarr.age;
    telegram = {
      file = ../../secrets/telegram.age;
      owner = "grafana";
      group = "grafana";
    };
    "telegram-qbittorrent" = {
      file = ../../secrets/telegram.age;
      owner = "thinkcentre";
      group = "thinkcentre";
    };
    "tailscale-exporter-api-key" = {
      file = ../../secrets/tailscale-exporter-api-key.age;
      owner = "tailscale-exporter";
      group = "tailscale-exporter";
      mode = "0400";
    };
    "headplane-cookie-secret" = {
      file = ../../secrets/headplane-cookie-secret.age;
      owner = "headscale";
      group = "headscale";
      mode = "0400";
    };
  };

  systemd = {
    coredump.enable = false;
    services.systemd-journal-flush.enable = false;
    targets.sleep.enable = false;
    targets.suspend.enable = false;
    targets.hibernate.enable = false;
    targets.hybrid-sleep.enable = false;
  };

  system.stateVersion = "25.11";
  networking.networkmanager.enable = true;
}
