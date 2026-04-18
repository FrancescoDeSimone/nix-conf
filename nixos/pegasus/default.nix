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
  ];

  networking.hostName = "pegasus";

  system.autoUpgrade.enable = true;
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
