{
  lib,
  stdenvNoCC,
  skopeo,
  python3,
}: let
  policyFile = builtins.toFile "skopeo-accept-any.json" ''
    { "default": [{ "type": "insecureAcceptAnything" }] }
  '';

  unpackScript = builtins.toFile "unpack-oci-layers.py" ''
    import json
    import os
    import subprocess
    import sys

    image, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)

    manifest = json.load(open(os.path.join(image, "manifest.json")))
    for layer in manifest["layers"]:
        blob = layer["digest"].split(":", 1)[1]
        subprocess.run(
            ["tar", "-xzf", os.path.join(image, blob), "-C", out], check=True
        )
        # Whiteouts belong to the layer that performs the deletion; process
        # them right after unpacking so later layers can still overlay.
        for dirpath, _, filenames in os.walk(out, topdown=False):
            for name in filenames:
                if not name.startswith(".wh."):
                    continue
                path = os.path.join(dirpath, name)
                if name == ".wh..wh..opq":
                    for entry in os.listdir(dirpath):
                        if entry != ".wh..wh..opq":
                            subprocess.run(
                                ["rm", "-rf", os.path.join(dirpath, entry)]
                            )
                else:
                    subprocess.run(["rm", "-rf", os.path.join(dirpath, name[4:])])
                os.remove(path)
  '';
in {
  # Unpacks a digest-pinned OCI image into a plain rootfs directory.
  mkTypetypeImageRootfs = {
    name,
    imageName,
    imageDigest,
    sha256,
    extraDirs ? [],
  }: let
    image = stdenvNoCC.mkDerivation {
      name = "${name}-image";
      nativeBuildInputs = [skopeo];
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = sha256;
      buildCommand = ''
        skopeo --policy ${policyFile} copy \
          docker://${imageName}@${imageDigest} \
          dir:$out
      '';
    };
  in
    stdenvNoCC.mkDerivation {
      inherit name;
      image = image;
      nativeBuildInputs = [python3];
      dontUnpack = true;
      dontFixup = true;
      installPhase = ''
        runHook preInstall
        python3 ${unpackScript} "${image}" "$out"
        ${lib.concatMapStrings (dir: ''
          mkdir -p "$out/${dir}"
        '')
        extraDirs}
        runHook postInstall
      '';
    };
}
