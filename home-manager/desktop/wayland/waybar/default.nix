{config, ...}: {
  imports = [./modules.nix ./style.nix];
  programs.waybar = {
    enable = true;
  };
}
