{
  outputs,
  pkgs,
  ...
}: {
  imports = [./desktop/default.nix ./cli/default.nix ./desktop/wayland/default.nix];
  home.packages = with pkgs; [
    neovim
    jellyfin-tui
    yq
    jq
    ayugram-desktop
  ];
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
      target = "graphical-session.target";
    };
  };
  home = {
    username = "fdesi";
    homeDirectory = "/home/fdesi";
    stateVersion = "25.11";
  };
}
