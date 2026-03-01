{ config
, private
, pkgs
, lib
, ...
}:
let
  email = private.nginx.email;
  domain = private.nginx.domain;
  provider = private.nginx.provider;

  # --- 1. Custom 404 Page Generation ---
  customErrorPage = pkgs.writeTextDir "share/nginx/html/404.html" ''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>404 - Service Not Found</title>
        <style>
            body {
                background-color: #1e1e2e; color: #cdd6f4; font-family: monospace;
                display: flex; flex-direction: column; align-items: center;
                justify-content: center; height: 100vh; margin: 0;
            }
            h1 { font-size: 6rem; margin: 0; color: #f38ba8; }
            p { font-size: 1.5rem; margin-top: 10px; }
            a { color: #89b4fa; text-decoration: none; margin-top: 20px; border-bottom: 2px solid #89b4fa; }
        </style>
    </head>
    <body>
        <h1>404</h1>
        <p>This service does not exist on Pegasus.</p>
        <a href="http://homepage.pegasus.lan">Return to Dashboard</a>
    </body>
    </html>
  '';

  # --- 2. Common Config (Error handling + Rate limiting) ---
  commonVhostConfig = ''
    error_page 404 /404.html;
    proxy_intercept_errors on;
    location = /404.html {
      root ${customErrorPage}/share/nginx/html;
      internal;
    }

    # Apply general rate limiting to all requests
    limit_req zone=general burst=50 nodelay;
  '';

  figletFonts = pkgs.runCommand "figlet-fonts" { } ''
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
in
{
  security.acme = {
    acceptTerms = true;
    defaults.email = email;
    certs.${domain} = {
      domain = "*." + domain;
      dnsProvider = provider;
      group = "nginx";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = false;
      environmentFile = config.age.secrets.provider.path;
    };
  };
  services.prometheus.exporters.nginx = {
    enable = true;
    port = config.my.services.nginx.exporter;
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    statusPage = true;

    commonHttpConfig = ''
      # Rate limiting
      limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
      limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
      limit_req_zone $binary_remote_addr zone=general:10m rate=30r/s;

      # Security headers
      add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header X-Frame-Options "SAMEORIGIN" always;
      add_header Referrer-Policy "strict-origin-when-cross-origin" always;
      add_header X-XSS-Protection "1; mode=block" always;
      add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
      add_header Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=()" always;

      # Limit request size
      client_body_buffer_size 128k;
    '';

    virtualHosts = {
      # --- CATCH-ALL DEFAULT ---
      "_" = {
        default = true;
        rejectSSL = true;
        locations."/" = {
          # Serve the 404 page directly
          root = "${customErrorPage}/share/nginx/html";
          tryFiles = "/404.html =404";
        };
      };

      # --- External Domains ---
      ${"nextcloud." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://192.168.100.10:${toString config.my.services.nextcloud.port}";
      };
      ${"jellyfin." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.jellyfin.port}";
      };
      ${"pdf." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.stirling-pdf.port}";
      };
      ${"it-tools." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        root = "${pkgs.it-tools}/lib";
        # FIX: Merged commonVhostConfig with specific config using string concatenation
        extraConfig =
          commonVhostConfig
          + ''
            index index.html;
            location /fonts/ { alias ${figletFonts}/; }
          '';
      };
      ${"bypass." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.bypass.port}";
      };
      ${"jellyseer." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.jellyseerr.port}";
      };
      ${"git." + domain} = {
        forceSSL = true;
        useACMEHost = domain;
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://192.168.200.11:${toString config.my.services.git.port}";
      };

      # --- Internal LAN Services ---
      "opencloud.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://192.168.103.11:${toString config.my.services.opencloud.port}";
      };
      "sonarr.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.sonarr.port}/";
      };
      "radarr.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.radarr.port}/";
      };
      "bypass.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.bypass.port}/";
      };
      "speedtracker.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.speedtesttracker.port}/";
      };
      "filebrowser.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.filebrowser.port}/";
      };
      "git.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://192.168.200.11:${toString config.my.services.git.port}/";
      };
      "glances.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.glances.port}/";
      };
      "jellyfin.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.jellyfin.port}/";
      };
      "prowlarr.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.my.services.prowlarr.port}/";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_read_timeout 300s;
          '';
        };
      };
      "scrutiny.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.scrutiny.port}/";
      };
      "pdf.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.stirling-pdf.port}/";
      };
      "qbittorrent.pegasus.lan" = {
        extraConfig =
          commonVhostConfig
          + ''
            # Stricter rate limiting for qbittorrent web interface
            limit_req zone=api burst=5 nodelay;
          '';
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.my.services.qui.port}/";
          proxyWebsockets = true;
        };
      };
      "hoarder.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.hoarder.port}/";
      };
      "homepage.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.homepage.port}/";
      };
      "lidarr.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://192.168.60.11:${toString config.my.services.lidarr.port}/";
      };
      "grafana.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.my.services.grafana.port}/";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_intercept_errors off;
          '';
        };
      };
      "prometheus.pegasus.lan" = {
        extraConfig = commonVhostConfig;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.my.services.prometheus.port}/";
      };
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 22 ];
  };
}
