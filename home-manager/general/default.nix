{ pkgs, lib, inputs, config, ... }: {
  imports = [ ./zsh.nix ./htop.nix ./tmux.nix ./starship.nix ];
  home.packages = with pkgs; [ home-manager ];
  xdg.enable = true;
}
