{
  pkgs,
  config,
  ...
}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_6_12;
    extraModulePackages = with config.boot.kernelPackages; [tuxedo-drivers yt6801];
    kernelParams = ["acpi.ec_no_wakeup=1" "amdgpu.dcdebugmask=0x10"];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      systemd.enable = true;
      availableKernelModules = ["nvme" "xhci_pci" "usb_storage" "sd_mod" "tpm_tis"];
    };

    kernel.sysctl = {
      "kernel.perf_event_paranoid" = 1;
      "kernel.kptr_restrict" = 0;
    };
  };

  hardware = {
    tuxedo-rs = {
      enable = true;
      tailor-gui.enable = true;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    firmware = with pkgs; [linux-firmware];
  };

  services.blueman.enable = true;
  services.power-profiles-daemon.enable = false;

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };
}
