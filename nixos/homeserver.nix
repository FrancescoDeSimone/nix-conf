{ inputs
, outputs
, lib
, config
, unstable
, pkgs
, ...
}: {
  # You can import other NixOS modules here
  imports = [
    ./homeserver/hardware-configuration.nix
    ./homeserver/services.nix
    ./homeserver/applications.nix
    #./homeserver/disks.nix
    ./homeserver/filesystem.nix
    ./homeserver/nextcloud.nix
    ./applications.nix
    ./homeserver/docker.nix
    ./general/lxd.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };
  system.autoUpgrade = {
    enable = true;
  };
  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit unstable inputs outputs; };
    users = {
      thinkcentre = import ../home-manager/homeserver.nix;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "homeserver";
  networking.networkmanager.enable = true;
  #systemd.coredump.enable = false;
  #services.journald.extraConfig = "Storage=volatile";
  #services.journald.forwardToSyslog = false;
  #systemd.services.systemd-journal-flush.enable = false;
  #services.logrotate.enable = false;
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  security.tpm2.enable = false;
  hardware.cpu.amd.updateMicrocode = true;
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };
  users.users.thinkcentre = {
    isNormalUser = true;
    description = "thinkcentre";
    extraGroups = [ "networkmanager" "wheel" "lxd" "docker" ];
  };
  services.openssh.enable = true;
  system.stateVersion = "23.05"; # Did you read the comment?
}
