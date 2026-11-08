{
  config,
  private,
  pkgs,
  inputs,
  lib,
  ...
}: let
  inherit (private.nginx) email domain provider internalDomain;

  # OwnTracks ingest path — acts as the shared secret in the URL the phone
  # posts to (owntracks.<domain>/<token>). Regenerate with:
  #   head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n'
  owntracksIngestToken = "c8e291cef7a5372cb25a46525b297d96";

  publicVhostAttrs = {
    forceSSL = true;
    useACMEHost = domain;
  };

  defaultAppCsp = "default-src 'self' http: https: data: blob: 'unsafe-inline' 'unsafe-eval';";
  mediaAppCsp = "default-src 'self' http: https: data: blob: 'unsafe-inline';";

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
        <a href="https://homepage.${internalDomain}">Return to Dashboard</a>
    </body>
    </html>
  '';
  baseSecurityHeaders = ''
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=()" always;
    server_tokens off;
  '';
  largeTransferTimeouts = ''
    # Relaxed timeouts for services handling uploads/downloads
    client_body_timeout 30s;
    client_header_timeout 30s;
    send_timeout 60s;
  '';
  # Verify the Kasm VM's TLS certificate once its CA is dropped in secrets/kasm-ca.pem
  kasmTlsVerifyConfig = lib.optionalString (builtins.pathExists ../../../secrets/kasm-ca.pem) ''
    proxy_ssl_verify on;
    proxy_ssl_trusted_certificate ${../../../secrets/kasm-ca.pem};
    proxy_ssl_verify_depth 2;
  '';
  errorPageRules = ''
    # Custom error page
    error_page 404 /404.html;
    proxy_intercept_errors on;
    location = /404.html {
      root ${customErrorPage}/share/nginx/html;
      internal;
    }
  '';

  hiddenPathRules = ''
    # Block all hidden files and directories (dotfiles),
    # except RFC 5785 service metadata (OIDC discovery etc.)
    # and OpenCloud app data (pastebin etc. live under .space/).
    location ~ /\.(?!well-known($|/)|space($|/)) {
      deny all;
      log_not_found off;
    }
  '';

  probeExtensionRules = ''
    # Block dangerous/probing file extensions
    location ~* \.(git|log|sql|env|yml|yaml|bak|php|asp|aspx|jsp|cgi|sh|py|pl|conf)$ {
      deny all;
    }
  '';

  defaultRobotsRules = ''
    # Crawl prevention
    location = /robots.txt {
      return 200 "User-agent: *\nDisallow: /admin\nDisallow: /config\nDisallow: /\n";
    }
  '';

  scannerBlockRules = ''
    # Block scanners and aggressive User-Agents
    if ($http_user_agent ~* (nmap|nikto|sqlmap|dirbuster|masscan|zgrab)) {
      return 403;
    }
  '';

  rateLimitRules = ''
    # Rate and connection limits
    limit_req zone=general burst=50 nodelay;
    limit_conn addr 20;
  '';

  cloudRobotsRules = ''
    # Crawl prevention
    location = /robots.txt {
      return 200 "User-agent: *\nDisallow: /\n";
    }
  '';

  mkVhostConfig = {
    csp ? null,
    extraConfig ? "",
    rules ? "",
  }:
    baseSecurityHeaders
    + lib.optionalString (csp != null) ''
      add_header Content-Security-Policy "${csp}" always;
    ''
    + extraConfig
    + rules;

  sharedAppRules =
    errorPageRules + hiddenPathRules + probeExtensionRules + defaultRobotsRules + scannerBlockRules;

  defaultAppRules = sharedAppRules + rateLimitRules;

  defaultAppVhostConfig = mkVhostConfig {
    csp = defaultAppCsp;
    rules = defaultAppRules;
  };

  largeTransferVhostConfig = mkVhostConfig {
    csp = defaultAppCsp;
    extraConfig = largeTransferTimeouts;
    rules = defaultAppRules;
  };

  jellyfinVhostConfig = mkVhostConfig {
    csp = mediaAppCsp;
    extraConfig = ''
      client_max_body_size 20M;

      # Long timeout for streaming responses to slow-but-alive clients
      send_timeout 3600s;

      # Disable error interception so Jellyfin controls its own responses
      proxy_intercept_errors off;
    '';
    # No rateLimitRules: the web client floods dozens of chunk requests
    # on load and Jellyfin has its own brute-force protection.
    rules = hiddenPathRules + probeExtensionRules + defaultRobotsRules + scannerBlockRules;
  };

  mkStreamingProxyConfig = {connectTimeout ? null}:
    ''
      # Streaming-friendly proxy settings
      proxy_buffering off;
      proxy_request_buffering off;
      proxy_read_timeout 3600s;
      proxy_send_timeout 3600s;
    ''
    + lib.optionalString (connectTimeout != null) ''
      proxy_connect_timeout ${connectTimeout};
    '';

  jellyfinProxyConfig = mkStreamingProxyConfig {connectTimeout = "10s";};

  grafanaVhostConfig = mkVhostConfig {
    csp = defaultAppCsp;
    rules = defaultAppRules;
  };

  # OpenCloud serves its own strict security headers; an extra nginx CSP
  # header only conflicts with them, so none is set here.
  opencloudVhostConfig = mkVhostConfig {
    extraConfig =
      largeTransferTimeouts
      + ''
        client_max_body_size 10G;
        proxy_request_buffering off;
      '';
    rules =
      hiddenPathRules
      + scannerBlockRules
      + cloudRobotsRules
      + rateLimitRules;
  };

  headscaleVhostConfig = mkVhostConfig {rules = defaultAppRules;};
  headscaleProxyConfig = mkStreamingProxyConfig {};
  mkHeadscaleVhost = {
    public ? false,
    accessPolicy ? null,
    tls ? null,
  }:
    mkProxyVhost {
      inherit public accessPolicy tls;
      upstream = "http://127.0.0.1:${toString config.my.services.headscale.port}";
      vhostConfig = headscaleVhostConfig;
      websockets = true;
      locationExtraConfig = headscaleProxyConfig;
    };
  gitUiAnubisInstance = "git-ui";
  gitUpstream = "http://192.168.200.11:${toString config.my.services.git.port}";
  gitUiAnubisUpstream = "http://unix:${
    config.services.anubis.instances.${gitUiAnubisInstance}.settings.BIND
  }";
  pdfUiAnubisInstance = "pdf-ui";
  pdfUiAnubisUpstream = "http://unix:${
    config.services.anubis.instances.${pdfUiAnubisInstance}.settings.BIND
  }";
  microbinUiAnubisInstance = "microbin-ui";
  microbinUiAnubisUpstream = "http://unix:${
    config.services.anubis.instances.${microbinUiAnubisInstance}.settings.BIND
  }";
  bypassUiAnubisInstance = "bypass-ui";
  bypassUiAnubisUpstream = "http://unix:${
    config.services.anubis.instances.${bypassUiAnubisInstance}.settings.BIND
  }";
  itToolsInternalHost = "it-tools.pegasus.lan";
  tailnetOnlyAccess = ''
    allow 100.64.0.0/10;
    allow fd7a:115c:a1e0::/48;
    allow 127.0.0.1;
    allow ::1;
    deny all;
  '';
  gitPublicLocations = {
    # Keep Git smart HTTP, LFS and API traffic unchallenged so CLI clients keep working.
    "^~ /.within.website/" = mkProxyLocation {upstream = gitUiAnubisUpstream;};
    "^~ /.well-known/" = mkProxyLocation {upstream = gitUpstream;};
    "^~ /api/" = mkProxyLocation {upstream = gitUpstream;};
    "^~ /v2/" = mkProxyLocation {upstream = gitUpstream;};
    # Login endpoints: throttle credential stuffing (exact match beats ^~ /api/ and /)
    "= /api/v1/users/signin" = mkProxyLocation {
      upstream = gitUpstream;
      extraConfig = "limit_req zone=login burst=10 nodelay;";
    };
    "= /user/login" = mkProxyLocation {
      upstream = gitUiAnubisUpstream;
      extraConfig = "limit_req zone=login burst=10 nodelay;";
    };
    "~ \\.git/(info/refs|git-upload-pack|git-receive-pack)$" = mkProxyLocation {
      upstream = gitUpstream;
    };
    "~ \\.git/info/lfs/" = mkProxyLocation {upstream = gitUpstream;};
    "/" = mkProxyLocation {upstream = gitUiAnubisUpstream;};
  };

  anubisAssetLocation = anubisUpstream:
    mkProxyLocation {
      upstream = anubisUpstream;
    };

  mkAnubisUiLocations = {
    anubisUpstream,
    appUpstream ? anubisUpstream,
    rootExtraConfig ? null,
  }: {
    "^~ /.within.website/" = anubisAssetLocation anubisUpstream;
    "/" = mkProxyLocation {
      upstream = appUpstream;
      extraConfig = rootExtraConfig;
    };
  };

  pdfPublicLocations = mkAnubisUiLocations {
    anubisUpstream = pdfUiAnubisUpstream;
    rootExtraConfig = ''
      client_max_body_size 100M;
    '';
  };

  # MicroBin caps 64M unencrypted / 16M encrypted
  microbinPublicLocations = mkAnubisUiLocations {
    anubisUpstream = microbinUiAnubisUpstream;
    rootExtraConfig = ''
      client_max_body_size 70M;
      # Let MicroBin serve its own errors: 404 here means "paste not found /
      # expired", not "vhost missing" (same rationale as the jellyfin vhost).
      proxy_intercept_errors off;
    '';
  };

  bypassPublicLocations = mkAnubisUiLocations {
    anubisUpstream = bypassUiAnubisUpstream;
  };

  mkVhost = {
    public ? false,
    extraConfig,
    accessPolicy ? null,
    root ? null,
    locations ? null,
    tls ? null,
    http2 ? null,
  }:
    (
      if public
      then publicVhostAttrs
      else {}
    )
    // (
      if tls != null
      then {
        forceSSL = true;
        useACMEHost = tls;
      }
      else {}
    )
    // {
      extraConfig = extraConfig + lib.optionalString (accessPolicy != null) accessPolicy;
    }
    // lib.optionalAttrs (root != null) {inherit root;}
    // lib.optionalAttrs (locations != null) {inherit locations;}
    // lib.optionalAttrs (http2 != null) {inherit http2;};

  mkProxyLocation = {
    upstream,
    websockets ? false,
    extraConfig ? null,
  }:
    {
      proxyPass = upstream;
    }
    // lib.optionalAttrs websockets {proxyWebsockets = true;}
    // lib.optionalAttrs (extraConfig != null) {inherit extraConfig;};

  mkProxyVhost = {
    public ? false,
    upstream,
    vhostConfig,
    accessPolicy ? null,
    websockets ? false,
    locationExtraConfig ? null,
    extraLocations ? {},
    tls ? null,
    http2 ? null,
  }:
    mkVhost {
      inherit public accessPolicy tls http2;
      extraConfig = vhostConfig;
      locations =
        {
          "/" = mkProxyLocation {
            inherit upstream websockets;
            extraConfig = locationExtraConfig;
          };
        }
        // extraLocations;
    };

  mkTailnetProxyVhost = args:
    mkProxyVhost (
      {
        accessPolicy = tailnetOnlyAccess;
        extraLocations = {};
      }
      // args
    );

  mkSimpleProxyVhosts = vhostConfig: hosts:
    builtins.listToAttrs (
      map
      (
        {
          name,
          public ? false,
          upstream,
          accessPolicy ? null,
          tls ? null,
        }:
          lib.nameValuePair name (mkProxyVhost {
            inherit
              public
              upstream
              vhostConfig
              accessPolicy
              tls
              ;
          })
      )
      hosts
    );

  mkCustomTailnetTlsService = ip: subdomain: port: {
    name = "${subdomain}.${internalDomain}";
    upstream = "http://${ip}:${toString port}/";
    accessPolicy = tailnetOnlyAccess;
    tls = internalDomain;
  };

  mkCustomPublicService = ip: subdomain: port: {
    name = "${subdomain}.${domain}";
    public = true;
    upstream = "http://${ip}:${toString port}";
  };
  mkTailnetTlsService = mkCustomTailnetTlsService "127.0.0.1";
  mkPublicService = mkCustomPublicService "127.0.0.1";

  figletFonts = pkgs.runCommand "figlet-fonts" {} ''
    mkdir -p $out
    cp ${
      pkgs.fetchurl {
        url = "https://unpkg.com/figlet@1.6.0/fonts/3D%20Diagonal.flf";
        sha256 = "sha256-CsZh0A4xMuCy6bny4jwolxprdbA+mmmOpsUkPjh+Lpc=";
      }
    } "$out/3D Diagonal.flf"
    cp ${
      pkgs.fetchurl {
        url = "https://unpkg.com/figlet@1.6.0/fonts/3D-ASCII.flf";
        sha256 = "sha256-ywpy1pJ7fKZbFxNCVfqkvfgXVApoPfNff70yt8lTBS4=";
      }
    } "$out/3D-ASCII.flf"
    cp ${
      pkgs.fetchurl {
        url = "https://unpkg.com/figlet@1.6.0/fonts/3x5.flf";
        sha256 = "sha256-Rtgtcb3b0AAYfsdSRdN8YO24gqmyE/gZqGRAsRYn5nY=";
      }
    } "$out/3x5.flf"
  '';

  defaultProxyVhosts =
    mkSimpleProxyVhosts defaultAppVhostConfig [
    ];

  defaultInternalVhosts = mkSimpleProxyVhosts defaultAppVhostConfig [
    # (mkTailnetTlsService "bypass" config.my.services.bypass.port)
    (mkTailnetTlsService "filebrowser" config.my.services.filebrowser.port)
    (mkTailnetTlsService "homepage" config.my.services.homepage.port)
    (mkTailnetTlsService "headplane" config.my.services.headplane.port)
  ];

  largeTransferProxyVhosts = mkSimpleProxyVhosts largeTransferVhostConfig [
    (mkCustomPublicService "192.168.200.11" "git" config.my.services.git.port)
  ];

  largeTransferInternalVhosts = mkSimpleProxyVhosts largeTransferVhostConfig [
    (mkCustomTailnetTlsService "192.168.200.11" "git" config.my.services.git.port)
    (mkTailnetTlsService "sonarr" config.my.services.sonarr.port)
    (mkTailnetTlsService "radarr" config.my.services.radarr.port)
    (mkTailnetTlsService "lidarr" config.my.services.lidarr.port)
    (mkTailnetTlsService "scrutiny" config.my.services.scrutiny.port)
    (mkTailnetTlsService "pdf" config.my.services.stirling-pdf.port)
    (mkTailnetTlsService "prometheus" config.my.services.prometheus.port)
  ];

  deemixVhostConfig = mkVhostConfig {
    csp = null;
    rules = defaultAppRules;
  };

  speedtrackerLocationConfig = ''
    proxy_buffer_size 16k;
    proxy_buffers 8 16k;
    proxy_busy_buffers_size 32k;
  '';

  staticVhosts = {
    "${itToolsInternalHost}" = {
      serverName = itToolsInternalHost;
      listen = [
        {
          addr = "0.0.0.0";
          port = config.my.services.it-tools.port;
        }
      ];
      root = "${pkgs.it-tools}/lib";
      extraConfig =
        defaultAppVhostConfig
        + ''
          ${tailnetOnlyAccess}
          index index.html;
          location /fonts/ { alias ${figletFonts}/; }
        '';
    };
    "paint.${domain}" = mkVhost {
      public = true;
      root = "${inputs.p5aint}";
      extraConfig =
        largeTransferVhostConfig
        + ''
          index index.html;
        '';
    };
    "it-tools.${internalDomain}" = {
      forceSSL = true;
      useACMEHost = internalDomain;
      root = "${pkgs.it-tools}/lib";
      extraConfig =
        defaultAppVhostConfig
        + ''
          ${tailnetOnlyAccess}
          index index.html;
          location /fonts/ { alias ${figletFonts}/; }
        '';
    };
  };
in {
  security.acme = {
    acceptTerms = true;
    defaults.email = email;
    certs.${domain} = {
      domain = "*." + domain;
      dnsProvider = provider;
      group = "nginx";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      environmentFile = config.age.secrets.provider.path;
    };
    certs.${internalDomain} = {
      domain = "*." + internalDomain;
      dnsProvider = provider;
      group = "nginx";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      environmentFile = config.age.secrets.provider.path;
    };
  };

  services = {
    prometheus.exporters.nginx = {
      enable = true;
      openFirewall = false;
      port = config.my.services.nginx.exporter;
      listenAddress = "127.0.0.1";
    };

    fail2ban = {
      enable = true;
      maxretry = 5;
      ignoreIP = [
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "127.0.0.0/8"
        "100.64.0.0/10"
        "fd7a:115c:a1e0::/48"
        "::1"
      ];
      jails = {
        nginx-noscan = {
          settings = {
            enabled = true;
            filter = "nginx-botsearch";
            logpath = "/var/log/nginx/error.log";
            maxretry = 2;
            bantime = "1d";
          };
        };

        nginx-url-probe = {
          settings = {
            enabled = true;
            filter = "nginx-url-probe";
            logpath = "/var/log/nginx/access.log";
            backend = "auto";
            maxretry = 5;
            findtime = "10m";
            bantime = "1h";
          };
        };

        nginx-auth = {
          settings = {
            enabled = true;
            filter = "nginx-auth";
            logpath = "/var/log/nginx/access.log";
            maxretry = 5;
            findtime = "10m";
            bantime = "1h";
          };
        };
      };
    };

    nginx = {
      enable = true;
      additionalModules = [pkgs.nginxModules.brotli];
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      statusPage = true;
      logError = "/var/log/nginx/error.log warn";
      commonHttpConfig = ''
        # Rate limiting
        limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
        limit_req_zone $binary_remote_addr zone=general:10m rate=30r/s;
        limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
        # GPS pings are small and infrequent (per-device ~1/min)
        limit_req_zone $binary_remote_addr zone=owntracks:10m rate=30r/m;
        limit_conn_zone $binary_remote_addr zone=addr:10m;

        # Limit request size
        client_body_buffer_size 128k;

        # Tight global timeouts (overridden per-vhost where needed)
        client_body_timeout 10s;
        client_header_timeout 10s;
        send_timeout 10s;

        # Hide upstream server identity
        proxy_hide_header X-Powered-By;

        log_format vhost_combined '$remote_addr - $remote_user [$time_local] '
                                  '"$request" $status $body_bytes_sent '
                                  '"$http_referer" "$http_user_agent" '
                                  '"$host" $request_time';
        access_log /var/log/nginx/access.log vhost_combined;

        geo $tailnet_allowed {
          default 0;
          100.64.0.0/10 1;
          fd7a:115c:a1e0::/48 1;
          127.0.0.1 1;
          ::1 1;
        }

        ssl_stapling on;
        ssl_stapling_verify on;
        resolver 1.1.1.1 valid=300s;
        resolver_timeout 5s;

        limit_req_status 429;
        limit_conn_status 429;

        brotli on;
        brotli_static on;
        brotli_comp_level 6;
        brotli_types
          text/plain
          text/css
          application/javascript
          application/json
          image/svg+xml
          application/xml+rss;
      '';

      virtualHosts =
        {
          # Wildcard redirect: .pegasus.lan → ${private.nginx.internalDomain}
          "~^(?<sub>.+)\\.pegasus\\.lan$" = {
            extraConfig = ''
              access_log off;
              return 301 https://$sub.${internalDomain}$request_uri;
            '';
          };
        }
        // defaultProxyVhosts
        // largeTransferProxyVhosts
        // defaultInternalVhosts
        // largeTransferInternalVhosts
        // staticVhosts
        // {
          "_" = {
            default = true;
            rejectSSL = true;
            extraConfig = "return 444;";
          };

          "owntracks.${domain}" = mkVhost {
            public = true;
            extraConfig = mkVhostConfig {
              rules =
                hiddenPathRules
                + probeExtensionRules
                + cloudRobotsRules
                + scannerBlockRules;
            };
            locations = let
              owntracksUpstream = "http://192.168.101.11:${toString config.my.services.owntracks.port}/";
              owntracksThrottle = "limit_req zone=owntracks burst=30 nodelay;";
            in {
              # The random path is the ingest shared secret; anything else 404s.
              "= /${owntracksIngestToken}" = mkProxyLocation {
                upstream = owntracksUpstream;
                extraConfig = owntracksThrottle;
              };
              "= /${owntracksIngestToken}/" = mkProxyLocation {
                upstream = owntracksUpstream;
                extraConfig = owntracksThrottle;
              };
            };
          };

          "opencloud.${domain}" = mkVhost {
            public = true;
            extraConfig = opencloudVhostConfig;
            locations = let
              opencloudUpstream = "https://192.168.103.11:${toString config.my.services.opencloud.port}/";
            in {
              # The container presents a self-signed cert; nginx is the only
              # HTTP client that reaches it.
              "/" = mkProxyLocation {
                upstream = opencloudUpstream;
                websockets = true;
                extraConfig = ''
                  proxy_ssl_verify off;
                  proxy_ssl_server_name on;
                '';
              };
              # Importer companion (uppy): canonical URL is public, so the
              # importer app pulls from anywhere.
              "= /companion" = {return = "301 /companion/";};
              "/companion/" = mkProxyLocation {
                upstream = "http://192.168.103.11:3020/companion/";
                websockets = true;
              };
            };
          };

          # TypeType: the frontend dist is static (extracted from the pinned
          # image), so this vhost has an explicit root; the proxy routes
          # mirror the upstream web image's nginx.conf.
          "typetype.${domain}" = mkVhost {
            public = true;
            root = "${pkgs.typetype-web}/html";
            extraConfig = mkVhostConfig {
              csp = mediaAppCsp;
              extraConfig =
                largeTransferTimeouts
                + ''
                client_max_body_size 2g;

                gzip on;
                gzip_static on;
                gzip_vary on;
                gzip_types text/plain text/css application/javascript application/json image/svg+xml;

                # The API owns its responses (SPA fallback + JSON errors),
                # so no proxy error interception.
                proxy_intercept_errors off;
              '';
              # No rateLimitRules: playback and downloads flood requests like
              # jellyfin (same rationale as jellyfinVhostConfig).
              rules = hiddenPathRules + probeExtensionRules + defaultRobotsRules + scannerBlockRules;
            };
            locations = let
              serverUpstream = "http://192.168.106.11:${toString config.my.services.typetype.port}";
              downloaderUpstream = "http://192.168.106.11:18093";
              versionNoCache = ''
                default_type application/json;
                expires -1;
              '';
              streamingProxy = ''
                client_max_body_size 2g;
                proxy_buffering off;
                proxy_read_timeout 300s;
                proxy_send_timeout 300s;
              '';
              bilibiliProxy = ''
                rewrite ^/api/bilibili/(.*)$ /$1 break;
                proxy_ssl_server_name on;
                proxy_set_header Host api.bilibili.com;
                proxy_set_header Referer "https://space.bilibili.com/";
                proxy_set_header User-Agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
                proxy_set_header Authorization "";
                proxy_set_header Cookie "";
                proxy_read_timeout 30s;
                proxy_send_timeout 30s;
              '';
            in {
              "= /api/version" = {
                alias = "${pkgs.typetype-web}/html/version.json";
                extraConfig = versionNoCache;
              };
              "= /api/version/web" = {
                alias = "${pkgs.typetype-web}/html/version-web.json";
                extraConfig = versionNoCache;
              };
              "= /api/version/server" = mkProxyLocation {
                upstream = serverUpstream + "/version";
                extraConfig = versionNoCache;
              };
              "= /api/version/token" = mkProxyLocation {
                upstream = "http://192.168.106.11:8081/version";
                extraConfig = versionNoCache;
              };
              "= /api/version/downloader" = mkProxyLocation {
                upstream = downloaderUpstream + "/version";
                extraConfig = versionNoCache;
              };

              "= /api/rss/feeds" = mkProxyLocation {
                upstream = serverUpstream + "/rss/feeds";
                extraConfig = streamingProxy;
              };
              "^~ /api/rss/feeds/" = mkProxyLocation {
                upstream = serverUpstream + "/rss/feeds/";
                extraConfig = streamingProxy;
              };

              # The five bilibili endpoints the web client fetches directly
              # (upstream proxies them with fixed headers + GET only).
              # recommendedProxySettings would re-set Host=$host AFTER our
              # own header, so it is off here.
              "= /api/bilibili/x/polymer/web-space/seasons_series_list" = {
                proxyPass = "https://api.bilibili.com";
                recommendedProxySettings = false;
                extraConfig = bilibiliProxy + ''limit_except GET { deny all; }'';
              };
              "= /api/bilibili/x/polymer/web-space/seasons_archives_list" = {
                proxyPass = "https://api.bilibili.com";
                recommendedProxySettings = false;
                extraConfig = bilibiliProxy + ''limit_except GET { deny all; }'';
              };
              "= /api/bilibili/x/series/archives" = {
                proxyPass = "https://api.bilibili.com";
                recommendedProxySettings = false;
                extraConfig = bilibiliProxy + ''limit_except GET { deny all; }'';
              };
              "= /api/bilibili/x/series/recArchivesByKeywords" = {
                proxyPass = "https://api.bilibili.com";
                recommendedProxySettings = false;
                extraConfig = bilibiliProxy + ''limit_except GET { deny all; }'';
              };
              "= /api/bilibili/x/web-interface/card" = {
                proxyPass = "https://api.bilibili.com";
                recommendedProxySettings = false;
                extraConfig = bilibiliProxy + ''limit_except GET { deny all; }'';
              };

              # Generic API: strip /api and serve straight from the JVM.
              "^~ /api/" = mkProxyLocation {
                upstream = serverUpstream;
                websockets = true;
                extraConfig = ''
                  rewrite ^/api/(.*)$ /$1 break;
                  client_max_body_size 2g;
                  proxy_buffering off;
                  proxy_read_timeout 300s;
                  proxy_send_timeout 300s;
                '';
              };

              # Prefix-preserving playback paths (upstream routes; SABR and
              # media proxies keep their path prefix).
              "^~ /sabr/" = mkProxyLocation {
                upstream = serverUpstream + "/sabr/";
                websockets = true;
                extraConfig = streamingProxy;
              };
              "^~ /streams/" = mkProxyLocation {
                upstream = serverUpstream + "/streams/";
                extraConfig = streamingProxy;
              };
              "= /proxy" = mkProxyLocation {
                upstream = serverUpstream + "/proxy";
                extraConfig = streamingProxy;
              };
              "^~ /proxy/" = mkProxyLocation {
                upstream = serverUpstream + "/proxy/";
                extraConfig = streamingProxy;
              };

              # The SPA itself.
              "/" = {
                tryFiles = "$uri $uri/ /index.html";
              };
              "~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$" = {
                extraConfig = ''
                  expires 1y;
                  add_header Cache-Control "public, immutable";
                  ${baseSecurityHeaders}
                  # Nested add_header kills parent headers, including this CSP.
                  add_header Content-Security-Policy "${mediaAppCsp}" always;
                '';
              };
            };
          };

          "seerr.${domain}" = mkVhost {
            public = true;
            extraConfig = largeTransferVhostConfig;
            locations = let
              seerrUpstream = "http://127.0.0.1:${toString config.my.services.seerr.port}";
            in {
              # Throttle Jellyseerr local login endpoint
              "= /api/v1/auth/local" = mkProxyLocation {
                upstream = seerrUpstream;
                extraConfig = "limit_req zone=login burst=10 nodelay;";
              };
              "/" = mkProxyLocation {upstream = seerrUpstream;};
            };
          };

          "git.${domain}" = mkVhost {
            public = true;
            extraConfig = largeTransferVhostConfig;
            locations = gitPublicLocations;
          };
          # "bypass.${domain}" = mkVhost {
          #   public = true;
          #   extraConfig = defaultAppVhostConfig;
          #   locations = bypassPublicLocations;
          # };
          "jellyfin.${domain}" = mkProxyVhost {
            public = true;
            upstream = "http://127.0.0.1:${toString config.my.services.jellyfin.port}";
            vhostConfig = jellyfinVhostConfig;
            websockets = true;
            locationExtraConfig = jellyfinProxyConfig;
            http2 = false;
          };

          "pdf.${domain}" = mkVhost {
            public = true;
            extraConfig = mkVhostConfig {
              csp = defaultAppCsp;
              extraConfig = largeTransferTimeouts;
              rules = defaultAppRules;
            };
            locations = pdfPublicLocations;
          };

          "paste.${domain}" = mkVhost {
            public = true;
            extraConfig = mkVhostConfig {
              csp = defaultAppCsp;
              extraConfig = largeTransferTimeouts;
              rules = defaultAppRules;
            };
            locations = microbinPublicLocations;
          };

          # openGym PWA: static root + /api proxied to the API unit (module:
          # modules/nixos/opengym). Passkeys need HTTPS (wildcard cert) and
          # RP_ID/ORIGIN bound to this exact hostname.
          "opengym.${domain}" = mkVhost {
            public = true;
            extraConfig =
              mkVhostConfig {
                csp = defaultAppCsp;
                rules = defaultAppRules;
              }
              + ''
                # Progress photos are uploaded through /api.
                client_max_body_size 25M;
              '';
            root = "${config.my.services.opengym.frontendPackage}/share/opengym";
            locations = {
              "/" = {
                tryFiles = "$uri $uri/ /index.html";
              };
              "^~ /api/" = mkProxyLocation {
                upstream = "http://127.0.0.1:${toString config.my.services.opengym.port}";
                # Pass JSON errors (sync conflicts, missing profiles) through:
                # intercepting 404 here would break the app's error handling.
                # The coach admin "test run" waits synchronously up to 90 s for
                # a full AI generation — stay past the 60 s default or nginx
                # answers 504 while the job is still running.
                extraConfig = ''
                  proxy_intercept_errors off;
                  proxy_read_timeout 300s;
                  proxy_send_timeout 300s;
                '';
              };
              # Exercise stills/animations: immutable per build, licensed for
              # openGym only (catalogue/media/NOTICE.md) — CORP keeps other
              # sites from embedding them. A location-level add_header drops
              # the server-level ones, so they are re-declared in full here
              # (the nginx.conf builder's gixy check enforces the complete
              # set); caching comes from `expires`, not add_header.
              "^~ /exercise-media/" = {
                extraConfig = ''
                  expires 30d;
                  ${baseSecurityHeaders}
                  add_header Content-Security-Policy "${defaultAppCsp}" always;
                  add_header Cross-Origin-Resource-Policy "same-origin" always;
                '';
              };
            };
          };

          "headscale.${domain}" = mkHeadscaleVhost {public = true;};

          # --- Internal TLS vhosts ---
          "adguard.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://127.0.0.1:${toString config.my.services.adguard.port}/";
            vhostConfig = largeTransferVhostConfig;
            websockets = true;
            tls = internalDomain;
          };
          "duplicati.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://192.168.103.11:${toString config.my.services.duplicati.port}/";
            vhostConfig = defaultAppVhostConfig;
            websockets = true;
            tls = internalDomain;
          };
          "olivetin.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://127.0.0.1:${toString config.my.services.olivetin.port}/";
            vhostConfig = defaultAppVhostConfig;
            websockets = true;
            tls = internalDomain;
          };

          "traccar.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://192.168.101.11:${toString config.my.services.traccar.port}/";
            vhostConfig = defaultAppVhostConfig;
            websockets = true;
            tls = internalDomain;
          };

          "adguard-exporter.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://127.0.0.1:9618/metrics";
            vhostConfig = largeTransferVhostConfig;
            tls = internalDomain;
          };

          "jellyfin.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://127.0.0.1:${toString config.my.services.jellyfin.port}/";
            vhostConfig = jellyfinVhostConfig;
            websockets = true;
            locationExtraConfig = jellyfinProxyConfig;
            tls = internalDomain;
            http2 = false;
          };

          "prowlarr.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://127.0.0.1:${toString config.my.services.prowlarr.port}/";
            vhostConfig = largeTransferVhostConfig;
            websockets = true;
            locationExtraConfig = ''
              proxy_read_timeout 300s;
            '';
            tls = internalDomain;
          };

          "qbittorrent.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://127.0.0.1:${toString config.my.services.qui.port}/";
            vhostConfig = largeTransferVhostConfig;
            websockets = true;
            locationExtraConfig = ''
              proxy_intercept_errors off;
            '';
            tls = internalDomain;
          };

          "grafana.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://127.0.0.1:${toString config.my.services.grafana.port}/";
            vhostConfig = grafanaVhostConfig;
            websockets = true;
            locationExtraConfig = ''
              proxy_intercept_errors off;
            '';
            tls = internalDomain;
          };

          "headscale.${internalDomain}" = mkHeadscaleVhost {
            accessPolicy = tailnetOnlyAccess;
            tls = internalDomain;
          };

          "speedtracker.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://127.0.0.1:${toString config.my.services.speedtest-tracker.port}/";
            vhostConfig = largeTransferVhostConfig;
            locationExtraConfig = speedtrackerLocationConfig;
            tls = internalDomain;
          };

          "karakeep.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://127.0.0.1:${toString config.my.services.karakeep.port}/";
            vhostConfig = largeTransferVhostConfig;
            locationExtraConfig = ''
              proxy_intercept_errors off;
              proxy_buffering off;
              proxy_set_header Accept-Encoding "";
            '';
            tls = internalDomain;
          };

          "deemix.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://127.0.0.1:${toString config.my.services.deemix.port}/";
            vhostConfig = deemixVhostConfig;
            websockets = true;
            tls = internalDomain;
          };


          "headplane.${internalDomain}" = mkVhost {
            accessPolicy = tailnetOnlyAccess;
            extraConfig = defaultAppVhostConfig;
            tls = internalDomain;
            locations = {
              "= /" = {
                return = "302 /admin/";
              };
              "/" = mkProxyLocation {
                upstream = "http://127.0.0.1:${toString config.my.services.headplane.port}/";
              };
            };
          };

          "9router.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://192.168.105.11:${toString config.my.services._9router.port}/";
            vhostConfig = defaultAppVhostConfig;
            websockets = true;
            # Completions stream as SSE and multimodal prompts carry images.
            locationExtraConfig =
              ''
                client_max_body_size 50m;
              ''
              + mkStreamingProxyConfig {};
            tls = internalDomain;
          };

          "kasm.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "https://192.168.120.11/";
            vhostConfig = largeTransferVhostConfig;
            websockets = true;
            locationExtraConfig = ''
              proxy_ssl_server_name on;
              proxy_ssl_name 192.168.120.11;
              ${kasmTlsVerifyConfig}
              proxy_buffering off;
              proxy_request_buffering off;
              proxy_read_timeout 3600s;
              proxy_send_timeout 3600s;
            '';
            tls = internalDomain;
          };
        };
    };
  };

  environment.etc = {
    "fail2ban/filter.d/nginx-url-probe.conf".text = ''
      [Definition]
      failregex = ^<HOST> \- \S+ \[.*?\] "\S+ \S*(/wp-admin|/phpmyadmin|/\.env|/\.git|/\.htaccess|/\.svn|/\.hg)
      ignoreregex =
    '';
    "fail2ban/filter.d/nginx-auth.conf".text = ''
      [Definition]
      failregex = ^<HOST> .*"(?:POST|GET) (?:/user/login|/api/v1/users/signin|/api/v1/auth/local|/login|/admin)(?:\?[^"]*)? HTTP/[^"]*" (?:401|403)
      ignoreregex =
    '';
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443 22];
  };
}
