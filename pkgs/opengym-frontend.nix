# openGym frontend: React/Vite PWA built to static files, with the exercise
# stills and animations staged next to the app (exercise-media/). Vendored
# from upstream contrib/nix/frontend.nix, with the source pinned via the
# opengym flake input.
{
  lib,
  buildNpmPackage,
  nodejs_22,
  importNpmLock,
  inputs,
}:
buildNpmPackage rec {
  pname = "opengym-frontend";
  version = (builtins.fromJSON (builtins.readFile "${inputs.opengym}/api/package.json")).version;

  # The frontend imports api/coach/core/* (../../api/coach/core/…), so the build
  # needs the repo root — same layout the Dockerfile uses (see web/Dockerfile).
  src = inputs.opengym;
  npmRoot = "frontend";

  nodejs = nodejs_22;

  npmDeps = importNpmLock {npmRoot = src + "/frontend";};
  npmConfigHook = importNpmLock.npmConfigHook;

  npmFlags = ["--ignore-scripts"];

  buildPhase = ''
    runHook preBuild
    cd frontend
    export NODE_ENV=production
    export PATH="$PWD/node_modules/.bin:$PATH"
    npm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/opengym
    cp -r dist/* $out/share/opengym/
    # The exercise stills and animations come from the source tree (catalogue/media, 180 px,
    # licensed from Gym visual for openGym only: see catalogue/media/NOTICE.md). The same script
    # the demo and Android builds use puts them at exercise-media/ next to the app, which is
    # where the app asks for them. Nothing is downloaded, at build time or at runtime.
    env -u APP_MEDIA_DIR node ../scripts/catalogue/stage-media.mjs $out/share/opengym
    runHook postInstall
  '';

  meta = {
    description = "openGym frontend — self-hosted gym & body-weight tracker PWA";
    homepage = "https://github.com/DuarteSantos8/openGym";
    license = lib.licenses.agpl3Plus;
    platforms = nodejs_22.meta.platforms;
  };
}
