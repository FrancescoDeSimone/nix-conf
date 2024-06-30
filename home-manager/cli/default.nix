{pkgs, ...}: {
  imports = [./zsh.nix ./htop.nix ./tmux.nix ./starship.nix];
  home.packages = with pkgs; [
    home-manager
    neovim
    git
    ripgrep
    cht-sh
    fd
    fzf
    unstable.rsync
  ];
  xdg.enable = true;
}
