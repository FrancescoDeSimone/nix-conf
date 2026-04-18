{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.modules.editors.neovim;
in {
  options.modules.editors.neovim = {
    extras = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Put this to false if you want install stuff manually";
    };
  };
  config = {
    home.packages = with pkgs;
      [
        git
        ripgrep
        fd
        unzip
        nodejs_24
        python315
        go
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
        statix
        deadnix
        alejandra
        nil
      ]
      ++ lib.optionals cfg.extras [
        unstable.neovim
      ];

    xdg.configFile."nvim" = {
      source = inputs.kickstart-nvim;
      recursive = true;
    };
  };
}
