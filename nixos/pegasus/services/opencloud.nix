{
  config,
  private,
  pkgs,
  lib,
  ...
}: let
  opencloudPort = config.my.services.opencloud.port;
  hostAddress = "192.168.103.10";
  localAddress = "192.168.103.11";
  stateDir = "/var/lib/opencloud";
  webApps = {
    pastebin = pkgs.fetchzip {
      url = "https://github.com/opencloud-eu/web-extensions/releases/download/pastebin-v2.1.0/pastebin-2.1.0.zip";
      hash = "sha256-0xkr1oOQoMm3yV46B8QeIqfzjOqwoorWdBPWimfIC78=";
      stripRoot = false;
    };
    unzip = pkgs.fetchzip {
      url = "https://github.com/opencloud-eu/web-extensions/releases/download/unzip-v2.1.0/unzip-2.1.0.zip";
      hash = "sha256-sDBGSJYw6wXEp1mBorDBTwHR/RJctQZYrAH1fJ4Yqxk=";
      stripRoot = false;
    };
    importer = pkgs.fetchzip {
      url = "https://github.com/opencloud-eu/web-extensions/releases/download/importer-v2.0.0/importer-2.0.0.zip";
      hash = "sha256-Jd8cPtB3ZWad1Th6tHtxuu/k67EnQVM1e7QJXp9m6Q4=";
      stripRoot = false;
    };
    "com.github.jankaritech.mdpresentation-viewer" = pkgs.fetchzip {
      url = "https://github.com/JankariTech/web-app-presentation-viewer/releases/download/3.0.0/mdpresentation-viewer-opencloud-3.0.0.zip";
      hash = "sha256-oC6WSGhbnIuPDP1qa/WV0Xp1+TQt1KBXMUMQciqD14s=";
      stripRoot = false;
    };
  };
in {
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-opencloud"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 root root -"
  ];

  containers.opencloud = {
    autoStart = true;
    privateNetwork = true;
    inherit hostAddress localAddress;

    bindMounts.${stateDir} = {
      hostPath = stateDir;
      isReadOnly = false;
    };

    config = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.services.opencloud;
      usesGeneratedConfig = (cfg.settings.opencloud or {}) == {};
      adminPasswordFile = "${cfg.stateDir}/bootstrap-admin-password";
    in {
      networking.hosts = {
        # Hairpin OIDC discovery through host nginx (port 443),
        # so the proxy can verify tokens against the public URL.
        "${hostAddress}" = ["opencloud.${private.nginx.internalDomain}"];
      };

      services.opencloud = {
        enable = true;
        address = "0.0.0.0";
        port = opencloudPort;
        url = "https://opencloud.${private.nginx.internalDomain}";
      };

      systemd.services.opencloud-init-config = lib.mkIf (cfg.enable && usesGeneratedConfig) {
        serviceConfig.ReadWritePaths = lib.mkForce [
          "/etc/opencloud"
          cfg.stateDir
        ];

        script = lib.mkForce ''
          set -eux
          config="''${OC_CONFIG_DIR}/opencloud.yaml"

          if [ ! -e "$config" ]; then
            if [ ! -e "${adminPasswordFile}" ]; then
              umask 0077
              ${pkgs.openssl}/bin/openssl rand -hex 16 > "${adminPasswordFile}"
              chown root:root "${adminPasswordFile}"
              chmod 0400 "${adminPasswordFile}"
            fi

            echo "Provisioning initial OpenCloud config..."
            opencloud init \
              --insecure "''${OC_INSECURE:-false}" \
              --admin-password "$(< "${adminPasswordFile}")" \
              --config-path "''${OC_CONFIG_DIR}"
            chown ${cfg.user}:${cfg.group} "$config"
          fi
        '';
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [opencloudPort];
      };

      # Point the importer web app at the local Companion instance.
      environment.etc."opencloud/apps.yaml".text = ''
        importer:
          config:
            companionUrl: 'https://opencloud.${private.nginx.internalDomain}/companion'
      '';

      # Seed declarative web apps (pastebin, unzip, ...) from the
      # nix store on every boot so version bumps apply cleanly.
      systemd.services.opencloud-web-apps = {
        description = "Install declarative OpenCloud web apps";
        before = ["opencloud.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          appsDir="${cfg.stateDir}/web/assets/apps"
          mkdir -p "$appsDir"
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: src: ''
            rm -rf "$appsDir/${name}"
            cp -r "${src}/${name}" "$appsDir/${name}"
          '') webApps)}
          chown -R ${cfg.user}:${cfg.group} "$appsDir"
        '';
      };

      networking.resolvconf.enable = false;
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";

      system.stateVersion = "25.11";
    };
  };
}
