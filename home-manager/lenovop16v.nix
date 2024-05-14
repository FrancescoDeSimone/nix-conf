{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other home-manager modules here
  imports = [ ./lenovop16v/default.nix ./general/default.nix ];

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
    username = "fdesi";
    homeDirectory = "/home/fdesi";
  };
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
  home.stateVersion = "23.05";
}
