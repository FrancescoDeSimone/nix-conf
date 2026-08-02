{
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
  inputs,
}: let
  python = python3.withPackages (ps: [
    ps.beautifulsoup4
    ps.flask
    ps.requests
  ]);
in
  stdenvNoCC.mkDerivation {
    pname = "13ft";
    version = "0-unstable-${inputs.thirteenft.shortRev}";

    src = inputs.thirteenft;

    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/share/13ft"
      cp -r app "$out/share/13ft/"

      substituteInPlace "$out/share/13ft/app/portable.py" \
        --replace-fail 'app.run(host="0.0.0.0", port=os.getenv("PORT") or 5000, debug=False)' 'app.run(host=os.environ.get("THIRTEENFT_HOST", "0.0.0.0"), port=int(os.environ.get("THIRTEENFT_PORT", "5000")), debug=False)'

      makeWrapper ${python}/bin/python "$out/bin/13ft" \
        --add-flags "$out/share/13ft/app/portable.py"

      runHook postInstall
    '';

    meta = with lib; {
      description = "Self-hosted 12ft.io replacement";
      homepage = "https://github.com/wasi-master/13ft";
      license = licenses.mit;
      mainProgram = "13ft";
      platforms = platforms.linux;
    };
  }
