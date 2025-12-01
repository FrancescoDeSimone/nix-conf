{
  outputs,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [./desktop/default.nix ./cli/default.nix ./desktop/wayland/default.nix];

  home.packages = with pkgs; [brightnessctl jellyfin-tui yq jq];

  catppuccin.enable = true;
  catppuccin.flavor = "mocha";
  nixpkgs = {
    overlays = [
      (final: prev: {
        rofi-calc = prev.rofi-calc.override {rofi-unwrapped = prev.rofi-wayland-unwrapped;};
        rofi-top = prev.rofi-top.override {rofi-unwrapped = prev.rofi-wayland-unwrapped;};
        rofi-vpn = prev.rofi-vpn.override {rofi-unwrapped = prev.rofi-wayland-unwrapped;};
      })
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
  home.stateVersion = "25.11";
}
