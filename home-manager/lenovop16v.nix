{ outputs, pkgs, ... }: {
  # You can import other home-manager modules here
  imports =
    [ ./desktop/default.nix ./cli/default.nix ./desktop/wayland/default.nix ];

  home.packages = with pkgs; [ ollama ];

  catppuccin.enable = true;
  catppuccin.flavor = "mocha";
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
  home.stateVersion = "23.11";
}
