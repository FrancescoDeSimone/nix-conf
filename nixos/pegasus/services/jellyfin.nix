{pkgs, lib, ...}: let
  introSkipperVersion = "1.10.11.22";
  introSkipper = pkgs.fetchzip {
    url = "https://github.com/intro-skipper/intro-skipper/releases/download/10.11/v${introSkipperVersion}/intro-skipper-v${introSkipperVersion}.zip";
    sha256 = "sha256-x8xxfJb2to3BIdneUj2FcPdMBbTt7kmhfvGtBqWlDQ4=";
  };

  # JellyClip injects its player UI into the web client's index.html, but the
  # web client ships read-only in the Nix store. Bake a copy of the web client
  # (with the JellyClip tags already inserted) at build time and launch Jellyfin
  # with --webdir pointing at that copy. No runtime writes to the web client are
  # needed, keeping this robust for a read-only store path and a non-root
  # service user (a runtime copy broke because the service user cannot chown).
  jellyfin = pkgs.jellyfin;
  jellyfinWithWeb = pkgs.runCommand "jellyfin-with-web" {
    meta.mainProgram = "jellyfin";
  } ''
    storweb="$(grep -o -- '--webdir=[^ ]*' "${jellyfin}/bin/jellyfin" | head -n1 | cut -d= -f2)"
    [ -n "$storweb" ] || { echo "ERROR: could not resolve store web dir from launcher" >&2; exit 1; }
    mkdir -p "$out/web" "$out/bin"

    cp -a "$storweb"/. "$out/web/"
    chmod -R u+w "$out/web"

    # Inject the JellyClip UI tags into the baked copy (idempotent marker).
    sed -i 's#</body>#<!-- JellyClip-Ui:start -->\n<link rel="stylesheet" href="configurationpage?name=jellyclip.css">\n<script src="configurationpage?name=jellyclip.js"></script>\n<!-- JellyClip-Ui:end -->\n</body>#' "$out/web/index.html"

    # the stock bin/jellyfin wrapper with only --webdir rewritten.
    cp "${jellyfin}/bin/jellyfin" "$out/bin/jellyfin"
    chmod 755 "$out/bin/jellyfin"
    sed -i "s#--webdir=[^ ]*#--webdir=$out/web#" "$out/bin/jellyfin"
  '';

  pluginDir = "/data/jellyfin/plugins";
  introSkipperTarget = "${pluginDir}/Intro Skipper_${introSkipperVersion}";
in {
  services.jellyfin = {
    enable = true;
    package = jellyfinWithWeb;
    openFirewall = false;
    user = "thinkcentre";
    dataDir = "/data/jellyfin";
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
    forceEncodingConfig = true;
    transcoding = {
      enableHardwareEncoding = true;
      hardwareEncodingCodecs.hevc = true;
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
        mpeg2 = true;
        vc1 = true;
        vp9 = true;
      };
      # Tone-mapping via VA-API is Intel-only; leaving the module default (true)
      # would break HDR transcoding on AMD.
      enableToneMapping = false;
      throttleTranscoding = true;
      enableSubtitleExtraction = true;
    };
  };

  # Intro Skipper runs `ffmpeg` from PATH at startup (it doesn't read
  # encoding.xml), but jellyfin-ffmpeg lives in the Nix store. Expose it.
  systemd.services.jellyfin.path = [ pkgs.jellyfin-ffmpeg ];

  systemd.services.jellyfin.preStart = lib.mkAfter ''
    mkdir -p "${pluginDir}"
    if [[ ! -d "${introSkipperTarget}" ]]; then
      rm -rf "${pluginDir}/Intro Skipper_0.2.0.9"
      rm -f "${pluginDir}/configurations/ConfusedPolarBear.Plugin.IntroSkipper.xml"
      cp -r ${introSkipper} "${introSkipperTarget}"
      chown -R thinkcentre:jellyfin "${introSkipperTarget}"
    fi

    # nixos-26.05 module cannot express these two options; patch encoding.xml
    # after the module writes it. Idempotent via the grep guard.
    encodingXml="/data/jellyfin/config/encoding.xml"
    if [[ -f "$encodingXml" ]] && ! grep -q EnableSegmentDeletion "$encodingXml"; then
      sed -i \
        -e 's#<TranscodingTempPath>.*</TranscodingTempPath>#<TranscodingTempPath>/dev/shm/jellyfin-transcodes</TranscodingTempPath>#' \
        -e 's#</EncodingOptions>#<EnableSegmentDeletion>true</EnableSegmentDeletion><SegmentKeepSeconds>720</SegmentKeepSeconds></EncodingOptions>#' \
        "$encodingXml"
    fi
    install -d -o thinkcentre -g jellyfin /dev/shm/jellyfin-transcodes
  '';
}
