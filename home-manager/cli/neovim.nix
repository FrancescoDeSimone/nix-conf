{
  pkgs,
  lib,
  ...
}: let
  kickstart-nvim = pkgs.fetchFromGitHub {
    owner = "FrancescoDeSimone";
    repo = "kickstart.nvim";
    rev = "7a8fea8982a0f7401d68c01c6b8f6fb91d56b5b4";
    sha256 = "sha256-o2cK6JrDfWBotpUWDJ8kBfU1ib0SNWdkOVUPGHdM5/g=";
  };
in {
  xdg.configFile."nvim" = {
    source = kickstart-nvim;
    recursive = true;
  };
}
