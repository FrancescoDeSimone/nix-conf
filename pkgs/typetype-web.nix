# TypeType web frontend: the built SPA serves from
# ${out}/html (including version.json) on the public nginx vhost, which also
# proxies the /api routes to the container services (replicating upstream
# nginx.conf). No release assets exist, so the dist comes from the
# digest-pinned official image; see pkgs/typetype-rootfs.nix for bumping.
{
  lib,
  pkgs,
  stdenvNoCC,
}: let
  inherit (pkgs.callPackage ./typetype-rootfs.nix {}) mkTypetypeImageRootfs;

  rootfs = mkTypetypeImageRootfs {
    name = "typetype-web-image";
    imageName = "ghcr.io/typetype-video/typetype";
    # TypeType 1.13.2: regenerate with the skopeo inspect command in
    # pkgs/typetype-rootfs.nix.
    imageDigest = "sha256:8a4a817df0a2418f2b83ad367a2fa6ea2f62075a221d50d2e888f90eb892f63a";
    sha256 = "sha256-niUOnGfzB6NeK0adBo7q/jLzuHB0EE+onDbpgWo9Qw4=";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "typetype-web";
    version = "1.13.2";

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      ln -s "${rootfs}/usr/share/nginx/html" $out/html
      runHook postInstall
    '';

    meta = {
      description = "TypeType web frontend (pinned image artifact)";
      license = lib.licenses.gpl3;
    };
  }
