{inputs, ...}: {
  imports = [
    ../common
    ./disks.nix
    ./hardware.nix
    ./user.nix
    ./desktop.nix
    ./ai.nix

    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.catppuccin.nixosModules.catppuccin
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = true;
    PermitRootLogin = "yes";
  };

  services.tailscale.enable = true;
}
