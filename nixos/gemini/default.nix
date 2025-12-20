{
  pkgs,
  inputs,
  outputs,
  config,
  lib,
  ...
}: {
  imports = [
    ./disks.nix
    inputs.nixos-hardware.nixosModules.tuxedo-pulse-15-gen2
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
  ];

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
    };
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  age.secrets = {
    user-password = {
      file = "${inputs.private}/user-password.age";
    };
    wifi = {
      file = "${inputs.private}/wifi.age";
      path = "/etc/NetworkManager/system-connections/wifi.nmconnection";
      mode = "600";
    };
  };
  age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  nixpkgs.hostPlatform = "x86_64-linux";
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  system.stateVersion = "25.11";

  boot = {
    kernelPackages = pkgs.linuxPackages_6_12;
    extraModulePackages = with config.boot.kernelPackages; [tuxedo-drivers yt6801];
    kernelParams = ["acpi.ec_no_wakeup=1" "amdgpu.dcdebugmask=0x10"];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      systemd.enable = true; # Required for TPM2 LUKS unlocking
      availableKernelModules = ["nvme" "xhci_pci" "usb_storage" "sd_mod" "tpm_tis"];
    };
  };

  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
  };
  services.power-profiles-daemon.enable = false;

  services.xserver.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  programs.sway = {
    enable = true;
  };

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  programs.zsh.enable = true;
  users.users = {
    fdesi = {
      isNormalUser = true;
      extraGroups = ["networkmanager" "wheel" "video" "audio"];
      shell = pkgs.zsh;
      hashedPasswordFile = config.age.secrets.user-password.path;
    };
  };
  networking.networkmanager.enable = true;
  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    useGlobalPkgs = true;
    useUserPackages = true;
    users.fdesi = {
      imports = [../../home-manager/gemini.nix inputs.catppuccin.homeModules.catppuccin];
    };
  };
}
