{pkgs, ...}: {
  services.jellyfin = {
    enable = true;
    openFirewall = false;
    user = "thinkcentre";
    dataDir = "/data/jellyfin";
    package = pkgs.unstable.jellyfin.override {
      jellyfin-web = pkgs.unstable.jellyfin-web.overrideAttrs (_: _: {
        installPhase = ''
          runHook preInstall
          sed -i "s#</body>#<!-- JellyClip-Ui:start -->\n<link rel=\"stylesheet\" href=\"configurationpage?name=jellyclip.css\\&v=0.2.0.0\">\n<script src=\"configurationpage?name=jellyclip.js\\&v=0.2.0.0\"></script>\n<!-- JellyClip-Ui:end -->\n</body>#" dist/index.html
          mkdir -p $out/share
          cp -a dist $out/share/jellyfin-web
          runHook postInstall
        '';
      });
    };
  };
}
