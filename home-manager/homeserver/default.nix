{ pkgs, lib, inputs, config, ... }: {
  imports = [ ./zsh.nix ./htop.nix ./tmux.nix ./starship.nix ];
  home.packages = with pkgs; [
    home-manager
    neovim
    git
    ripgrep
    fd
    fzf
    unstable.rsync
  ];
  xdg.enable = true;
}
