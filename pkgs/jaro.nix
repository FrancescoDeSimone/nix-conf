{
  lib,
  stdenv,
  inputs,
  guile,
  xdg-utils,
  makeWrapper,
}:
stdenv.mkDerivation {
  pname = "jaro";
  version = "0-unstable-${inputs.jaro.shortRev}";

  src = inputs.jaro;

  nativeBuildInputs = [makeWrapper];
  buildInputs = [guile];

  installPhase = ''
    mkdir -p $out/bin
    cp jaro $out/bin/jaro
    chmod +x $out/bin/jaro

    # Wrap jaro to ensure it finds guile and has access to the REAL xdg-open for fallbacks
    wrapProgram $out/bin/jaro \
      --prefix PATH : "${lib.makeBinPath [guile xdg-utils]}"
  '';

  meta = with lib; {
    description = "Just another resource opener";
    homepage = "https://github.com/isamert/jaro";
    license = licenses.gpl3;
    maintainers = [];
    mainProgram = "jaro";
  };
}
