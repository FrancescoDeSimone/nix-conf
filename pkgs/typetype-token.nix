# TypeType token microservice: a bun-built JS bundle that drives Playwright
# Chromium (BotGuard PO tokens, remote login, subtitle decoding). The
# mcr.microsoft.com/playwright runner image ships exactly the browser builds
# expected by the bundled node_modules, so the needed subsets are linked out
# of the digest-pinned image instead of rebuilding playwright in Nix. See
# pkgs/typetype-rootfs.nix for digest bumping instructions.
{
  lib,
  pkgs,
  stdenvNoCC,
}: let
  inherit (pkgs.callPackage ./typetype-rootfs.nix {}) mkTypetypeImageRootfs;

  rootfs = mkTypetypeImageRootfs {
    name = "typetype-token-image";
    imageName = "ghcr.io/typetype-video/typetype-token";
    # TypeType 1.13.2: regenerate with the skopeo inspect command in
    # pkgs/typetype-rootfs.nix.
    imageDigest = "sha256:f1d9d022490b7ebbc6e5dc06f0b24692939bcd43e08d8084b0ffe51c2f94ab22";
    sha256 = "sha256-739exjcXfquaRXA6j2Bv7JRM2o/EXx+ycHC5ftt6fPI=";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "typetype-token";
    version = "1.13.2";

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/apps/token
      # dist --external playwright needs the production node_modules next to it.
      ln -s "${rootfs}/app/dist" $out/apps/token/dist
      ln -s "${rootfs}/app/node_modules" $out/apps/token/node_modules
      # Bun 1.4.4 from the image: upstream dist targets this exact runtime.
      ln -s "${rootfs}/usr/local/bin/bun" $out/bin/bun
      # Playwright resolves browsers by registry revision under this path.
      ln -s "${rootfs}/ms-playwright" $out/ms-playwright
      # Chromium's shared libraries (arena of libnss3/libgbm/...) shipped in
      # the runner image; the service points LD_LIBRARY_PATH at this dir.
      ln -s "${rootfs}/usr/lib/x86_64-linux-gnu" $out/syslibs

      runHook postInstall
    '';

    passthru = {
      browserEnv = {
        PLAYWRIGHT_BROWSERS_PATH = "${rootfs}/ms-playwright";
        LD_LIBRARY_PATH = "${rootfs}/usr/lib/x86_64-linux-gnu";
      };
    };

    meta = {
      description = "TypeType token service (BotGuard/subtitles; pinned image artifacts)";
      license = lib.licenses.gpl3;
    };
  }
