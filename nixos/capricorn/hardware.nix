{
  pkgs,
  config,
  lib,
  ...
}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = ["amd-pstate"];
    initrd.luks.cryptoModules = lib.mkIf (lib.versionAtLeast config.boot.kernelPackages.kernel.version "7.0") [
      "aes"
      "cbc"
      "xts"
      "sha256"
      "sha512"
      "af_alg"
      "algif_skcipher"
    ];
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
      availableKernelModules = ["nvme" "xhci_pci" "usb_storage" "sd_mod" "tpm_tis"];
    };

    kernel.sysctl = {
      "kernel.perf_event_paranoid" = 1;
      "vm.vfs_cache_pressure" = 50;
      "vm.swappiness" = 10;
      "kernel.kptr_restrict" = 0;
    };
  };

  hardware = {
    graphics = {
      enable = true; # mesa/RADV — required for Vulkan inference
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    firmware = with pkgs; [linux-firmware];
  };

  services = {
    blueman.enable = true;

    # TLP owns the power policy. Keep the machine in performance mode on both
    # AC and battery; power-profiles-daemon must stay disabled or it can switch
    # the Slimbook platform profile back to balanced.
    power-profiles-daemon.enable = false;
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "performance";
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 1;
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "performance";
      };
    };

    # Closing the lid is not a suspend action on this always-on inference host.
    logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };

    thermald.enable = true;
  };
}
