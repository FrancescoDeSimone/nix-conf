{
  pkgs,
  lib,
  inputs,
  ...
}: let
  # kickstart-nvim = pkgs.fetchFromGitHub {
  #   owner = "FrancescoDeSimone";
  #   repo = "kickstart.nvim";
  #   rev = "21f6d8dc8531bf7ce9937b02ee29488dd4bf3a9e";
  #   sha256 = "sha256-IEDSDhquU4moWcK5O5T05HjtJk8orCnY0xcrtRwk804=";
  # };
in {
  home.packages = with pkgs; [
    neovim
    nodejs_24
    python315
    go
    gcc
    gcc
    pkg-config
    hadolint
    clj-kondo
    markdownlint-cli
    vale
    ruby
    tflint
    stylua
    black
    prettierd
    shellcheck
    rustfmt
    alejandra
    git
    ripgrep
    fd
    unzip
  ];
  xdg.configFile."nvim" = {
    source = inputs.kickstart-nvim;
    recursive = true;
  };
}
