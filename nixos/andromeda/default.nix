{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    ./disks.nix
    ./hardware.nix
    ./user.nix
    ./desktop.nix

    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.catppuccin.nixosModules.catppuccin
  ];

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
    };
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  system.stateVersion = "25.11";

  networking.networkmanager.enable = true;
  networking.hostName = "andromeda";
}
