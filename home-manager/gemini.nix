{
  outputs,
  pkgs,
  ...
}: {
  imports = [./desktop/default.nix ./cli/default.nix ./desktop/wayland/default.nix];
  home.packages = with pkgs; [jellyfin-tui yq jq ayugram-desktop];
  catppuccin.enable = true;
  catppuccin.flavor = "mocha";
  wayland.windowManager.sway = {
    package = null;
    config.bars = [];
  };
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      # This ensures it starts for both Sway and Hyprland
      target = "graphical-session.target";
    };
  };
  nixpkgs = {
    overlays = [
      (final: prev: {
        rofi-calc = prev.rofi-calc.override {rofi-unwrapped = prev.rofi-unwrapped;};
        rofi-top = prev.rofi-top.override {rofi-unwrapped = prev.rofi-unwrapped;};
        rofi-vpn = prev.rofi-vpn.override {rofi-unwrapped = prev.rofi-unwrapped;};
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

  home.packages = with pkgs; [
    neovim
  ];
  home = {
    username = "fdesi";
    homeDirectory = "/home/fdesi";
  };
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.11";
}
