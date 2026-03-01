{ pkgs
, config
, inputs
, private
, ...
}: {
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.config/.password-store";
    };
  };

  home.file.".config/.password-store" = {
    source = inputs.private.inputs.password-store-repo;
    recursive = true;
  };
}
