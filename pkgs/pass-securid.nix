{
  lib,
  stdenv,
  openssl,
  inputs,
  ...
}:
stdenv.mkDerivation {
  pname = "pass-securid";
  version = "1.0.0";
  src = inputs.pass-securid;

  dontBuild = true;

  buildInputs = [openssl];

  patchPhase = ''
    sed -i \
      -e 's|command -v openssl|command -v ${openssl}/bin/openssl|' \
      -e 's|openssl kdf|${openssl}/bin/openssl kdf|g' \
      -e 's|openssl version|${openssl}/bin/openssl version|' \
      securid.bash
  '';

  installFlags = [
    "PREFIX=$(out)"
    "BASHCOMPDIR=$(out)/share/bash-completions/completions"
  ];

  meta = {
    description = "A pass extension for managing RSA SecurID software tokens";
    homepage = "https://www.passwordstore.org/";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
  };
}
