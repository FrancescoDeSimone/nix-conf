{pkgs, ...}: {
  services.jellyfin = {
    enable = true;
    openFirewall = false;
    user = "thinkcentre";
    dataDir = "/data/jellyfin";
    package = pkgs.jellyfin.override {
      jellyfin-web = pkgs.jellyfin-web.overrideAttrs (_: _: {
        installPhase = ''
          runHook preInstall
          sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script></head>#" dist/index.html
          sed -i "s#</body>#<!-- JellyClip-Ui:start -->\n<link rel=\"stylesheet\" href=\"configurationpage?name=jellyclip.css\">\n<script src=\"configurationpage?name=jellyclip.js\"></script>\n<!-- JellyClip-Ui:end -->\n</body>#" dist/index.html
          mkdir -p $out/share
          cp -a dist $out/share/jellyfin-web
          runHook postInstall
        '';
      });
    };
  };
}
