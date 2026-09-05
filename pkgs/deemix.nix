{
  lib,
  stdenv,
  nodejs,
  pnpm,
  fetchPnpmDeps,
  pnpmConfigHook,
  python3,
  makeWrapper,
  inputs,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "deemix";
  version = "4.6.0";

  src = inputs.deemix;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    hash = "sha256-uvi7hudXj6yaaRM7q9iWpa2E/SKUvXnjTWZlzhcEgFQ=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    python3
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild
    patchShebangs node_modules packages/*/node_modules
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/deemix
    cp -r . $out/share/deemix/

    makeWrapper ${nodejs}/bin/node $out/bin/deemix-webui \
      --add-flags $out/share/deemix/packages/webui/dist/main.js \
      --set NODE_ENV production

    makeWrapper ${nodejs}/bin/node $out/bin/deemix-cli \
      --add-flags $out/share/deemix/packages/cli/dist/main.cjs

    runHook postInstall
  '';

  meta = {
    description = "deemix — Deezer downloader (webui server + cli)";
    homepage = "https://github.com/bambanah/deemix";
    license = lib.licenses.gpl3Only;
    mainProgram = "deemix-webui";
  };
})
