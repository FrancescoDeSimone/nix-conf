{
  lib,
  pkgs,
  stdenvNoCC,
}: let
  inherit (pkgs.callPackage ./typetype-rootfs.nix {}) mkTypetypeImageRootfs;

  rootfs = mkTypetypeImageRootfs {
    name = "typetype-server-image";
    imageName = "ghcr.io/typetype-video/typetype-server";
    # TypeType 1.13.2: regenerate with the skopeo inspect command in
    # pkgs/typetype-rootfs.nix.
    imageDigest = "sha256:385158a1b13b7720a2a2efbef2a132cbcbe0ec35d4d4d00b3c82ee7458a67d45";
    sha256 = "sha256-/QS4KX3L7fuMxJ7ffPvnANdo/o7NeMubbMNLIdfzbrU=";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "typetype-server";
    version = "1.13.2";

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp "${rootfs}/app/app.jar" $out/lib/typetype-server-all.jar
      runHook postInstall
    '';

    # The jar embeds its build stamp; the digest pins byte-identical layers.
    passthru.imageDigest = "385158a1b13b7720a2a2efbef2a132cbcbe0ec35d4d4d00b3c82ee7458a67d45";

    meta = {
      description = "TypeType self-hosted video platform API server (pinned image artifact)";
      license = lib.licenses.gpl3;
    };
  }
