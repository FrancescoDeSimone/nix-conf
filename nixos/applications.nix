{ pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    git
    neovim
    tmux
    fzf
  ];

}
