{
  config,
  private,
  pkgs,
  inputs,
  lib,
  ...
}: let
  inherit (private.nginx) email domain provider internalDomain;

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
    # Block all hidden files and directories (dotfiles)
    location ~ /\. {
      deny all;
      access_log off;
      log_not_found off;
    }
  '';

  probeExtensionRules = ''
    # Block dangerous/probing file extensions
    location ~* \.(git|log|sql|env|yml|yaml|bak|php|asp|aspx|jsp|cgi|sh|py|pl|conf)$ {
      deny all;
      access_log off;
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

  nextcloudRobotsRules = ''
    # Crawl prevention
    location = /robots.txt {
      return 200 "User-agent: *\nDisallow: /\n";
    }
  '';

  nextcloudWellKnownRules = ''
    # Nextcloud .well-known redirects (must come after dotfile block)
    location ^~ /.well-known/ {
      allow all;
    }
    location ^~ /.well-known/carddav { return 301 $scheme://$host/remote.php/dav; }
    location ^~ /.well-known/caldav  { return 301 $scheme://$host/remote.php/dav; }
    location ^~ /.well-known/webfinger { return 301 $scheme://$host/index.php/.well-known/webfinger; }
    location ^~ /.well-known/nodeinfo  { return 301 $scheme://$host/index.php/.well-known/nodeinfo; }
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

      # Disable error interception so Jellyfin controls its own responses
      proxy_intercept_errors off;
    '';
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

  nextcloudVhostConfig = mkVhostConfig {
    extraConfig =
      largeTransferTimeouts
      + ''
        client_max_body_size 0;
        proxy_request_buffering off;
      '';
    rules =
      hiddenPathRules
      + scannerBlockRules
      + nextcloudRobotsRules
      + rateLimitRules
      + nextcloudWellKnownRules;
  };

  grafanaVhostConfig = mkVhostConfig {csp = defaultAppCsp;};

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
  bypassUiAnubisInstance = "bypass-ui";
  bypassUiAnubisUpstream = "http://unix:${
    config.services.anubis.instances.${bypassUiAnubisInstance}.settings.BIND
  }";
  itToolsInternalHost = "it-tools.pegasus.lan";
  tailnetOnlyAccess = ''
    if ($tailnet_allowed = 0) {
      return 444;
    }
  '';
  gitPublicLocations = {
    # Keep Git smart HTTP, LFS and API traffic unchallenged so CLI clients keep working.
    "^~ /.within.website/" = mkProxyLocation {upstream = gitUiAnubisUpstream;};
    "^~ /.well-known/" = mkProxyLocation {upstream = gitUpstream;};
    "^~ /api/" = mkProxyLocation {upstream = gitUpstream;};
    "^~ /v2/" = mkProxyLocation {upstream = gitUpstream;};
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
    // lib.optionalAttrs (locations != null) {inherit locations;};

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
    tls ? null,
  }:
    mkVhost {
      inherit public accessPolicy tls;
      extraConfig = vhostConfig;
      locations = {
        "/" = mkProxyLocation {
          inherit upstream websockets;
          extraConfig = locationExtraConfig;
        };
      };
    };

  mkTailnetProxyVhost = args:
    mkProxyVhost (
      {
        accessPolicy = tailnetOnlyAccess;
      }
      // args
    );

  mkSimpleProxyVhosts = vhostConfig: hosts:
    builtins.listToAttrs (
      map (
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

  defaultProxyVhosts = mkSimpleProxyVhosts defaultAppVhostConfig [
    (mkPublicService "bypass" config.my.services.bypass.port)
  ];

  defaultInternalVhosts = mkSimpleProxyVhosts defaultAppVhostConfig [
    (mkCustomTailnetTlsService "192.168.103.11" "opencloud" config.my.services.opencloud.port)
    (mkTailnetTlsService "bypass" config.my.services.bypass.port)
    (mkTailnetTlsService "filebrowser" config.my.services.filebrowser.port)
    (mkTailnetTlsService "homepage" config.my.services.homepage.port)
    (mkTailnetTlsService "headplane" config.my.services.headplane.port)
  ];

  largeTransferProxyVhosts = mkSimpleProxyVhosts largeTransferVhostConfig [
    (mkPublicService "jellyseer" config.my.services.jellyseerr.port)
    (mkCustomPublicService "192.168.200.11" "git" config.my.services.git.port)
  ];

  largeTransferInternalVhosts = mkSimpleProxyVhosts largeTransferVhostConfig [
    (mkCustomTailnetTlsService "192.168.200.11" "git" config.my.services.git.port)
    (mkTailnetTlsService "sonarr" config.my.services.sonarr.port)
    (mkTailnetTlsService "radarr" config.my.services.radarr.port)
    (mkTailnetTlsService "lidarr" config.my.services.lidarr.port)
    (mkTailnetTlsService "scrutiny" config.my.services.scrutiny.port)
    (mkTailnetTlsService "pdf" config.my.services.stirling-pdf.port)
    (mkTailnetTlsService "it-tools" config.my.services.it-tools.port)
    (mkTailnetTlsService "karakeep" config.my.services.karakeep.port)
    (mkTailnetTlsService "prometheus" config.my.services.prometheus.port)
  ];

  speedtrackerLocationConfig = ''
    proxy_buffer_size 16k;
    proxy_buffers 8 16k;
    proxy_busy_buffers_size 32k;
  '';

  staticVhosts = {
    "${itToolsInternalHost}" = {
      serverName = itToolsInternalHost;
      serverAliases = ["it-tools.${domain}"];
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
      dnsPropagationCheck = false;
      environmentFile = config.age.secrets.provider.path;
    };
    certs.${internalDomain} = {
      domain = "*." + internalDomain;
      dnsProvider = provider;
      group = "nginx";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = false;
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
      commonHttpConfig = ''
        # Rate limiting
        limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
        limit_req_zone $binary_remote_addr zone=general:10m rate=30r/s;
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

          "nextcloud.${domain}" = mkProxyVhost {
            public = true;
            upstream = "http://192.168.100.10:${toString config.my.services.nextcloud.port}";
            vhostConfig = nextcloudVhostConfig;
          };

          "git.${domain}" = mkVhost {
            public = true;
            extraConfig = largeTransferVhostConfig;
            locations = gitPublicLocations;
          };
          "bypass.${domain}" = mkVhost {
            public = true;
            extraConfig = defaultAppVhostConfig;
            locations = bypassPublicLocations;
          };
          "jellyfin.${domain}" = mkProxyVhost {
            public = true;
            upstream = "http://127.0.0.1:${toString config.my.services.jellyfin.port}";
            vhostConfig = jellyfinVhostConfig;
            websockets = true;
            locationExtraConfig = jellyfinProxyConfig;
          };

          "pdf.${domain}" = mkVhost {
            public = true;
            extraConfig = mkVhostConfig {
              csp = defaultAppCsp;
              extraConfig = largeTransferTimeouts;
              rules = sharedAppRules;
            };
            locations = pdfPublicLocations;
          };

          "headscale.${domain}" = mkHeadscaleVhost {public = true;};

          # --- Internal TLS vhosts ---
          "adguard.${internalDomain}" = mkTailnetProxyVhost {
            upstream = "http://127.0.0.1:${toString config.my.services.adguard.port}/";
            vhostConfig = largeTransferVhostConfig;
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
        };
    };
  };

  environment.etc = {
    "fail2ban/filter.d/nginx-url-probe.conf".text = ''
      [Definition]
      failregex = ^<HOST> \- \S+ \[.*?\] "\S+ \S*(/wp-admin|/phpmyadmin|/\.env|/\.git|/\.htaccess|/\.svn|/\.hg)
      ignoreregex =
    '';
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443 22];
  };
}
