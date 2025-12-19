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
  xdg.configFile."nvim" = {
    source = inputs.kickstart-nvim;
    recursive = true;
  };
}
