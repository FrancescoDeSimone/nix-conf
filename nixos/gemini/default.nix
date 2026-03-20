{ pkgs
, inputs
, lib
, config
, ...
}: {
  imports = [
    ../common
    ./disks.nix
    ./hardware.nix
    ./user.nix
    ./desktop.nix
    ./gaming.nix

    inputs.nixos-hardware.nixosModules.tuxedo-pulse-15-gen2
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.catppuccin.nixosModules.catppuccin
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
