# pass-securid: a pass extension for RSA SecurID software tokens.
# Sources the engine from the local `pass-securid` flake input; the python3
# path is baked in because the pass wrapper only carries a fixed PATH.
{
  lib,
  stdenv,
  python3,
  inputs,
  ...
}:
stdenv.mkDerivation {
  pname = "pass-securid";
  version = "1.0.0";
  src = inputs.pass-securid;

  dontBuild = true;

  buildInputs = [python3];

  patchPhase = ''
    sed -i -e 's|SECURID_PYTHON=''${PASSWORD_STORE_SECURID_PYTHON:-python3}|SECURID_PYTHON=${python3}/bin/python3|' securid.bash
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
