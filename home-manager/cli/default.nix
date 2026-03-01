{ pkgs, ... }: {
  imports = [
    ./zsh.nix
    ./htop.nix
    ./tmux.nix
    ./starship.nix
    ./neovim.nix
    ./jaro.nix
    ./yazi.nix
  ];
  home.packages = with pkgs; [
    home-manager
    git
    ripgrep
    cht-sh
    fd
    fzf
    sshuttle
    unstable.rsync
    unzip
    unstable.yt-dlp
  ];
  xdg.enable = true;
}
