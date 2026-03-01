{ pkgs
, modulesPath
, config
, lib
, ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # --- Bootloader & Kernel ---
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "amd_iommu=off" ];
    initrd = {
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
      kernelModules = [ "amdgpu" ];
    };
    kernelModules = [ "kvm-amd" ];
    blacklistedKernelModules = [ "bluetooth" "snd_hda_intel" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # --- Graphics ---
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      rocmPackages.clr
      rocmPackages.rocminfo
      rocmPackages.rocm-runtime
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # --- Processor ---
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  security.tpm2.enable = false;

  # --- File Systems ---
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/90960cf8-fc03-4167-a2af-f7cd817c7836";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3832-D7E7";
    fsType = "vfat";
  };
  swapDevices = [
    { device = "/dev/disk/by-uuid/7c640529-e1e4-440d-804a-a0768c54af71"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
