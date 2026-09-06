{
  lib,
  stdenv,
  fetchPnpmDeps,
  pnpmConfigHook,
  python3,
  makeWrapper,
  inputs,
  pkgs,
}: let
  deemixNixpkgs = inputs.deemix.inputs.nixpkgs.legacyPackages.${stdenv.hostPlatform.system};
  nodejs = deemixNixpkgs.nodejs_24;
  pnpm = deemixNixpkgs.pnpm_11;
  src = inputs.deemix;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "deemix";
  version = "4.6.0";

  inherit src;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    hash = "sha256-3AoDW1QFAUvXZ9wWtJUXRz6gfxez9pMrh98RJcsKEIY=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    python3
    makeWrapper
    pkgs.jq
  ];

  buildPhase = ''
    runHook preBuild
    ${pkgs.jq}/bin/jq '.packageManager = "pnpm@11.8.0"' package.json > package.json.tmp && mv package.json.tmp package.json
    patchShebangs node_modules packages/*/node_modules
    sed -i 's/this.downloadObject.collection\./this.downloadObject.collection?./g' packages/deemix/src/downloader.ts
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
