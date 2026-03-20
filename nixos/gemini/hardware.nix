{ pkgs
, config
, ...
}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = with config.boot.kernelPackages; [ tuxedo-drivers yt6801 ];
    kernelModules = [ "amd-pstate" ];
    kernelParams = [
      "acpi.ec_no_wakeup=1"
      "amdgpu.dcdebugmask=0x10"
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      "zswap.zpool=zsmalloc"
      "zswap.max_pool_percent=20"
      "amd_pstate=active"
      "amdgpu.ppfeaturemask=0xffffffff"
    ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      systemd.enable = true;
      availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" "tpm_tis" ];
    };

    kernel.sysctl = {
      "kernel.perf_event_paranoid" = 1;
      "vm.vfs_cache_pressure" = 50;
      "vm.swappiness" = 10;
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
    firmware = with pkgs; [ linux-firmware ];
  };

  services.blueman.enable = true;
  services.power-profiles-daemon.enable = true;

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  environment.systemPackages = with pkgs; [
    lact
    lm_sensors
  ];

  services.thermald.enable = true;
}
