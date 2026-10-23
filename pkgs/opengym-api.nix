# openGym API server: plain node:http with passkey auth (WebAuthn) and
# per-user workout JSON storage. Vendored from upstream contrib/nix/api.nix,
# with the source pinned via the opengym flake input.
{
  lib,
  buildNpmPackage,
  nodejs_22,
  makeWrapper,
  importNpmLock,
  inputs,
}:
buildNpmPackage rec {
  pname = "opengym-api";
  version = (builtins.fromJSON (builtins.readFile "${inputs.opengym}/api/package.json")).version;

  src = inputs.opengym + "/api";

  nodejs = nodejs_22;

  npmDeps = importNpmLock {npmRoot = src;};
  npmConfigHook = importNpmLock.npmConfigHook;

  dontNpmBuild = true;

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/opengym-api
    cp -r node_modules $out/lib/opengym-api/
    cp -r coach $out/lib/opengym-api/
    # Every top-level module server.js imports: server.js, password.js, passkeys-store.js,
    # rate-limit.js, media.js, device-link.js, push-messages.js, verify-error.js. Copy the
    # glob rather than an explicit list — a hand-kept list silently ships an incomplete tree
    # and the failure only shows up as ERR_MODULE_NOT_FOUND in the systemd journal.
    cp ./*.js $out/lib/opengym-api/

    mkdir -p $out/bin
    makeWrapper ${nodejs_22}/bin/node $out/bin/opengym-api \
      --add-flags "$out/lib/opengym-api/server.js" \
      --set NODE_ENV production
    runHook postInstall
  '';

  meta = {
    description = "openGym API — passkey auth + per-user workout data (Node.js)";
    homepage = "https://github.com/DuarteSantos8/openGym";
    license = lib.licenses.agpl3Plus;
    platforms = nodejs_22.meta.platforms;
  };
}
