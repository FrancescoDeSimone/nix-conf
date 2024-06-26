{ inputs, outputs, lib, config, unstable, pkgs, ... }: {
  imports = [
    ./pegasus/hardware-configuration.nix
    ./pegasus/services.nix
    ./pegasus/applications.nix
    #./pegasus/disks.nix
    ./pegasus/filesystem.nix
    ./pegasus/nextcloud.nix
    ./pegasus/git.nix
    ./pegasus/cron.nix
    ./applications.nix
    ./pegasus/docker.nix
    ./general/lxd.nix
    ./pegasus/homepage.nix
    #inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = { allowUnfree = true; };
  };
  system.autoUpgrade = { enable = true; };
  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}")
      config.nix.registry;
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

  #home-manager = {
  #  extraSpecialArgs = { inherit unstable inputs outputs; };
  #  users = { thinkcentre = import ../home-manager/pegasus.nix; };
  #};

  boot.kernelParams = [ "amd_iommu=off" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      rocm-opencl-icd
      rocm-opencl-runtime
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [ "bluetooth" "snd_hda_intel" ];

  networking.hostName = "pegasus";
  networking.networkmanager.enable = true;
  systemd.coredump.enable = false;
  services.journald.extraConfig = "Storage=volatile";
  services.journald.forwardToSyslog = false;
  systemd.services.systemd-journal-flush.enable = false;
  services.logrotate.enable = false;
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
  system.stateVersion = "24.05"; # Did you read the comment?
}
