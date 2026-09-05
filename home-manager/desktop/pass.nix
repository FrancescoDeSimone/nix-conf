{
  pkgs,
  config,
  inputs,
  ...
}: let
  pass-audit = pkgs.pass.extensions.pass-audit.overrideAttrs (_: {
    version = "unstable-2025-05-14";
    doCheck = false;
    src = pkgs.fetchFromGitHub {
      owner = "roddhjav";
      repo = "pass-audit";
      rev = "92b8fe5709bfbaaadf4c2f1db2ff0c7c1d014503";
      hash = "sha256-iZJkem3kUUJb8sGcLCaQMvmq9705UDwMYG+R6s9Db0w=";
    };
  });

  # git textconv driver: decrypts a *.gpg file to stdout so `git diff`
  # shows plaintext diffs. Git invokes it as: gpg-diff <path-to-encrypted-file>
  gpg-diff = pkgs.writeShellScriptBin "gpg-diff" ''
    exec ${pkgs.gnupg}/bin/gpg --quiet --decrypt "$1"
  '';
in {
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [
      exts.pass-otp
      exts.pass-update
      pass-audit
      pkgs.pass-securid
    ]);
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.config/.password-store";
    };
  };

  home.file.".config/.password-store" = {
    source = inputs.private.inputs.password-store-repo;
    recursive = true;
  };

  # Non-destructive git config for readable plaintext diffs of encrypted
  # *.gpg files (merged alongside the manually-managed ~/.gitconfig).
  home.file.".config/git/config".text = ''
    [diff "gpg"]
      textconv = ${gpg-diff}/bin/gpg-diff
  '';

  home.packages = [
    gpg-diff
    pkgs.passepartui
  ];
}
