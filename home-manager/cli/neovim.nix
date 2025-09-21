{
  pkgs,
  lib,
  ...
}: let
  kickstart-nvim = pkgs.fetchFromGitHub {
    owner = "FrancescoDeSimone";
    repo = "kickstart.nvim";
    rev = "698d78f5144c2b4ffb8cacf3dab7575e5cf06691";
    sha256 = "sha256-aZGJmUMzL1M/oe34K4i3uWGvoB58ZBJsCtSWTI/UUq0=";
  };
in {
  programs.neovim = {
    enable = true;
  };

  xdg.configFile."nvim" = {
    source = kickstart-nvim;
    recursive = true;
  };
}
