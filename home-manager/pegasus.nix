{outputs, ...}: {
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
    username = "thinkcentre";
    homeDirectory = "/home/thinkcentre";
  };
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.05";
}
