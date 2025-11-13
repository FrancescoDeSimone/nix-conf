{
  config,
  private,
  pkgs,
  ...
}: let
  email = private.nginx.email;
  domain = private.nginx.domain;
  provider = private.nginx.provider;
in {
  security.acme = {
    acceptTerms = true;
    preliminarySelfsigned = true;
    defaults.email = email;
    certs.${domain} = {
      domain = "*." + domain;
      dnsProvider = provider;
      #server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      group = "nginx";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = false;
      environmentFile = config.age.secrets.provider.path;
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      ${"nextcloud." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/".proxyPass = "http://192.168.100.10:8010";
      };
      ${"jellyfin." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/".proxyPass = "http://127.0.0.1:8096";
      };
      ${"pdf." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/".proxyPass = "http://127.0.0.1:8080";
      };
      ${"it-tools." + domain} = let
        figletFonts = pkgs.runCommand "figlet-fonts" {} ''
                  mkdir -p $out
                  cp ${pkgs.fetchurl {
            url = "https://unpkg.com/figlet@1.6.0/fonts/3D%20Diagonal.flf";
            sha256 = "sha256-CsZh0A4xMuCy6bny4jwolxprdbA+mmmOpsUkPjh+Lpc=";
          }} "$out/3D Diagonal.flf"
                    cp ${pkgs.fetchurl {
            url = "https://unpkg.com/figlet@1.6.0/fonts/3D-ASCII.flf";
            sha256 = "sha256-ywpy1pJ7fKZbFxNCVfqkvfgXVApoPfNff70yt8lTBS4=";
          }} "$out/3D-ASCII.flf"

          cp ${pkgs.fetchurl {
            url = "https://unpkg.com/figlet@1.6.0/fonts/3x5.flf";
            sha256 = "sha256-Rtgtcb3b0AAYfsdSRdN8YO24gqmyE/gZqGRAsRYn5nY=";
          }} "$out/3x5.flf"
        '';
      in {
        forceSSL = true;
        useACMEHost = domain;
        root = "${pkgs.it-tools}/lib";
        extraConfig = ''
          index index.html;

          location /fonts/ {
            alias ${figletFonts}/;
          }
        '';
      };
      ${"bypass." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/".proxyPass = "http://127.0.0.1:5000";
      };
      ${"jellyseer." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/".proxyPass = "http://127.0.0.1:5055";
      };
      ${"git." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/".proxyPass = "http://192.168.200.11:3001";
      };

      "opencloud.pegasus.local" = {
        locations."/".proxyPass = "http://192.168.103.11:80";
      };
    };
  };

  networking.firewall = {
    enable = false;
    # allowedTCPPorts = [80 443 22];
  };
}
