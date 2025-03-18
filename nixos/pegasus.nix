{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./pegasus/hardware-configuration.nix
    ./pegasus/services.nix
    ./pegasus/applications.nix
    ./pegasus/filesystem.nix
    ./pegasus/cron.nix
    ./applications.nix
    ./general/lxd.nix
  ];

  age.secrets = {
    provider = {
      file = ../secrets/provider.age;
    };
    hoarder = {
      file = ../secrets/hoarder.age;
    };
  };
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {allowUnfree = true;};
  };
  system.autoUpgrade = {enable = true;};
  nix = {
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath =
      lib.mapAttrsToList (key: value: "${key}=${value.to.path}")
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

  services.xserver.videoDrivers = ["amdgpu"];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # rocm-opencl-icd
      # rocm-opencl-runtime
      rocmPackages_5.clr.icd
      rocmPackages_5.clr
      rocmPackages_5.rocminfo
      rocmPackages_5.rocm-runtime
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  boot = {
    kernelParams = ["amd_iommu=off"];
    initrd.kernelModules = ["amdgpu"];
    kernelPackages = pkgs.linuxPackages_latest;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    blacklistedKernelModules = ["bluetooth" "snd_hda_intel"];
  };

  networking = {
    hostName = "pegasus";
    networkmanager.enable = true;
  };
  systemd = {
    coredump.enable = false;
    services.systemd-journal-flush.enable = false;
    targets.sleep.enable = false;
    targets.suspend.enable = false;
    targets.hibernate.enable = false;
    targets.hybrid-sleep.enable = false;
  };

  security.tpm2.enable = false;
  hardware.cpu.amd.updateMicrocode = true;
  programs.zsh.enable = true;

  time.timeZone = "Europe/Rome";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
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
  };
  users = {
    defaultUserShell = pkgs.zsh;
    users.thinkcentre = {
      isNormalUser = true;
      description = "thinkcentre";
      extraGroups = ["networkmanager" "wheel" "lxd" "docker"];
    };
  };
  system.stateVersion = "24.11"; # Did you read the comment?
}
