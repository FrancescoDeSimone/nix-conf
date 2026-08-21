{
  pkgs,
  config,
  inputs,
  ...
}: let
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
      exts.pass-audit
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
