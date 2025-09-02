{config, ...}: {
  imports = [./modules.nix ./style.nix];
  programs.waybar = {
    enable = true;
  };
  # catppuccin.waybar.enable = config.catppuccin.enable;
}
