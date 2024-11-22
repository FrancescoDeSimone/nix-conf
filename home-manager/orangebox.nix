{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [./cli/default.nix];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };
  home = {
    username = "ubuntu";
    homeDirectory = "/home/ubuntu";
  };
  systemd.user.startServices = "sd-switch";
  home.stateVersion = "24.05";
}
