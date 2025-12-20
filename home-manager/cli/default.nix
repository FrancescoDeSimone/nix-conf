{pkgs, ...}: {
  imports = [./zsh.nix ./htop.nix ./tmux.nix ./starship.nix ./neovim.nix];
  home.packages = with pkgs; [
    home-manager
    git
    ripgrep
    cht-sh
    fd
    fzf
    sshuttle
    unstable.rsync
    yazi
  ];
  xdg.enable = true;
}
