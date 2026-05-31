{
  pkgs,
  config,
  private,
  lib,
  ...
}: let
  provider = private.nginx.provider;
  providerStatistic = private.nginx.provider-statistic;

  capitalize = s:
    if (builtins.stringLength s) > 0
    then (lib.toUpper (builtins.substring 0 1 s)) + (builtins.substring 1 (builtins.stringLength s) s)
    else s;

  titleCase = s: lib.concatMapStringsSep " " capitalize (lib.splitString "-" s);

  hiddenServices = [
    "adguard-exporter"
    "homepage"
    "headscale"
    "opencloud"
  ];

  serviceOverrides = {
    adguard = {
      name = "AdGuard";
      group = "Network";
      description = "DNS filtering and local resolver";
      icon = "mdi-shield-check-outline";
      widget = {
        type = "adguard";
        url = "http://127.0.0.1:${toString config.my.services.adguard.port}";
        username = "admin";
        password = "";
      };
    };
    bypass = {
      name = "Bypass";
      group = "Network";
      description = "Routing and access bypass";
      icon = "mdi-swap-horizontal";
    };
    filebrowser = {
      name = "Filebrowser";
      group = "Daily";
      description = "Web file manager";
      icon = "mdi-folder-multiple-outline";
    };
    git = {
      name = "Git";
      group = "Daily";
      description = "Self-hosted Git service";
      icon = "mdi-source-repository";
    };
    grafana = {
      name = "Grafana";
      group = "Observability";
      description = "Dashboards and alerts";
      icon = "mdi-chart-donut-variant";
    };
    headplane = {
      name = "Headplane";
      group = "Network";
      description = "Headscale admin panel";
      icon = "mdi-cog-outline";
    };
    it-tools = {
      name = "IT Tools";
      group = "Utilities";
      description = "Developer and IT toolkit";
      icon = "mdi-tools";
    };
    kasm = {
      name = "Kasm";
      group = "Daily";
      description = "Containerized workspaces";
      icon = "mdi-desktop-classic";
    };
    jellyfin = {
      name = "Jellyfin";
      group = "Media";
      description = "Media streaming";
      icon = "mdi-play-box-multiple-outline";
    };
    karakeep = {
      name = "Karakeep";
      group = "Daily";
      description = "Saved links and knowledge";
      icon = "mdi-bookmark-box-multiple-outline";
    };
    lidarr = {
      name = "Lidarr";
      group = "Media";
      description = "Music library automation";
      icon = "mdi-music-note-eighth";
    };
    nextcloud = {
      name = "Nextcloud";
      group = "Daily";
      description = "Files, sync, and collaboration";
      icon = "mdi-cloud-sync-outline";
    };
    opencloud = {
      name = "OpenCloud";
      group = "Daily";
      description = "Remote cloud workspace";
      icon = "mdi-cloud-outline";
    };
    olivetin = {
      name = "OliveTin";
      group = "Utilities";
      description = "Self-service server actions";
      icon = "mdi-console";
    };
    pdf = {
      name = "Stirling PDF";
      group = "Utilities";
      description = "PDF conversion and editing";
      icon = "mdi-file-pdf-box";
    };
    prometheus = {
      name = "Prometheus";
      group = "Observability";
      description = "Metrics collection";
      icon = "mdi-fire-circle";
      widget = {
        type = "prometheus";
        url = "http://127.0.0.1:${toString config.my.services.prometheus.port}";
      };
    };
    prowlarr = {
      name = "Prowlarr";
      group = "Media";
      description = "Indexer management";
      icon = "mdi-radar";
    };
    qbittorrent = {
      name = "qBittorrent";
      group = "Media";
      description = "Torrent downloads";
      icon = "mdi-download-network-outline";
    };
    radarr = {
      name = "Radarr";
      group = "Media";
      description = "Movie library automation";
      icon = "mdi-movie-open-outline";
    };
    scrutiny = {
      name = "Scrutiny";
      group = "Observability";
      description = "Disk health monitoring";
      icon = "mdi-harddisk";
      widget = {
        type = "scrutiny";
        url = "http://127.0.0.1:${toString config.my.services.scrutiny.port}";
      };
    };
    sonarr = {
      name = "Sonarr";
      group = "Media";
      description = "Series library automation";
      icon = "mdi-television-classic";
    };
    speedtracker = {
      name = "Speedtest Tracker";
      group = "Observability";
      description = "Internet performance history";
      icon = "mdi-speedometer";
    };
  };

  groupOrder = [
    "Daily"
    "Media"
    "Network"
    "Observability"
    "Utilities"
    "Other"
  ];

  groupLayouts = {
    Daily = {
      icon = "mdi-home-outline";
      style = "row";
      columns = 3;
    };
    Media = {
      icon = "mdi-play-circle-outline";
      style = "row";
      columns = 4;
    };
    Network = {
      icon = "mdi-lan";
      style = "row";
      columns = 3;
    };
    Observability = {
      icon = "mdi-chart-box-outline";
      style = "row";
      columns = 3;
    };
    Utilities = {
      icon = "mdi-tools";
      style = "row";
      columns = 2;
    };
    Other = {
      icon = "mdi-application-outline";
      style = "row";
      columns = 4;
    };
    External = {
      icon = "mdi-open-in-new";
      style = "row";
      columns = 2;
    };
  };

  serviceHostnames = lib.sort (a: b: a < b) (lib.attrNames lanHosts);

  serviceEntries = lib.sort (a: b: a.displayName < b.displayName) (map (host: let
      name = lib.removeSuffix ".${private.nginx.internalDomain}" host;
      override = serviceOverrides.${name} or {};
      displayName = override.name or (titleCase name);
      widgetConfig = override.widget or {};
    in {
      inherit displayName;
      group = override.group or "Other";
      item = {
        "${displayName}" =
          {
            id = name;
            href = "https://${host}";
            description = override.description or "${displayName} service";
            icon = override.icon or "mdi-application-outline";
          }
          // lib.optionalAttrs (widgetConfig != {}) {
            widget = widgetConfig;
          };
      };
    })
    serviceHostnames);

  presentGroups = builtins.filter (group: builtins.elem group entryGroups) groupOrder;

  entryGroups = lib.unique (map (entry: entry.group) serviceEntries);

  layout =
    map (group: {"${group}" = groupLayouts.${group};}) presentGroups
    ++ [
      {
        External = groupLayouts.External;
      }
    ];

  manualItems = {
    Network = [
      {
        "FRITZ!Box" = {
          href = "http://192.168.188.1";
          description = "Router and network gateway";
          icon = "mdi-router-network";
          widget = {
            type = "fritzbox";
            url = "http://192.168.188.1";
          };
        };
      }
    ];
  };

  serviceGroups =
    lib.concatMap
    (group: let
      autoItems = map (entry: entry.item) (lib.filter (entry: entry.group == group) serviceEntries);
      extra = manualItems.${group} or [];
      items = autoItems ++ extra;
    in
      lib.optional (items != []) {"${group}" = items;})
    groupOrder;

  lanHosts =
    lib.filterAttrs
    (host: _: let
      serviceName = lib.removeSuffix ".${private.nginx.internalDomain}" host;
    in
      lib.hasSuffix ".${private.nginx.internalDomain}" host && !(builtins.elem serviceName hiddenServices))
    config.services.nginx.virtualHosts;
in {
  systemd.services.homepage-dashboard.environment = {
    HOMEPAGE_ALLOWED_HOSTS = lib.mkForce "homepage.${private.nginx.internalDomain}";
  };

  services.homepage-dashboard = {
    enable = true;
    openFirewall = false;
    listenPort = config.my.services.homepage.port;
    package = pkgs.unstable.homepage-dashboard;

    settings = {
      title = "Pegasus";
      description = "Daily services, media, and observability";
      theme = "dark";
      color = "slate";
      headerStyle = "boxedWidgets";
      iconStyle = "theme";
      cardBlur = "md";
      fullWidth = true;
      useEqualHeights = true;
      disableCollapse = true;
      hideVersion = true;
      disableUpdateCheck = true;
      hideErrors = true;
      disableIndexing = true;
      inherit layout;
      quicklaunch = {
        provider = "duckduckgo";
        searchDescriptions = true;
        showSearchSuggestions = true;
        mobileButtonPosition = "bottom-right";
      };
    };

    services = serviceGroups;

    bookmarks = [
      {
        External = [
          {
            "${titleCase provider} Stats" = [
              {
                href = providerStatistic;
                description = "Upstream provider analytics";
                icon = "mdi-chart-line";
                target = "_blank";
              }
            ];
          }
        ];
      }
    ];

    widgets = [
      {
        search = {
          provider = [
            "duckduckgo"
            "google"
          ];
          target = "_blank";
          showSearchSuggestions = true;
        };
      }
      {
        resources = {
          cpu = true;
          disk = "/";
          memory = true;
        };
      }
      {
        datetime = {
          text_size = "xl";
          format = {
            dateStyle = "medium";
            timeStyle = "short";
            hourCycle = "h23";
          };
        };
      }
    ];

    customCSS = ''
      :root {
        --pegasus-card: linear-gradient(180deg, rgba(15, 23, 42, 0.76), rgba(15, 23, 42, 0.52));
        --pegasus-card-hover: linear-gradient(180deg, rgba(30, 41, 59, 0.84), rgba(30, 41, 59, 0.62));
        --pegasus-border: rgba(148, 163, 184, 0.16);
        --pegasus-glow: rgba(56, 189, 248, 0.18);
      }

      body {
        background-image:
          radial-gradient(circle at top left, rgba(56, 189, 248, 0.16), transparent 26rem),
          radial-gradient(circle at top right, rgba(168, 85, 247, 0.14), transparent 22rem),
          linear-gradient(180deg, rgba(15, 23, 42, 0.98), rgba(2, 6, 23, 1));
        background-attachment: fixed;
      }

      .service-card,
      .bookmark > a,
      .widget-container {
        border: 1px solid var(--pegasus-border);
        background: var(--pegasus-card) !important;
        box-shadow: 0 14px 36px rgba(2, 6, 23, 0.28);
      }

      .service-card:hover,
      .bookmark > a:hover,
      .widget-container:hover {
        background: var(--pegasus-card-hover) !important;
        border-color: rgba(125, 211, 252, 0.24);
        box-shadow:
          0 18px 44px rgba(2, 6, 23, 0.34),
          0 0 0 1px var(--pegasus-glow);
        transform: translateY(-1px);
      }

      .service-group-name,
      .bookmark-group-name {
        letter-spacing: 0.03em;
      }

      .service-icon,
      .bookmark-icon,
      .service-group-icon,
      .bookmark-group-icon {
        filter: drop-shadow(0 10px 18px rgba(15, 23, 42, 0.35));
      }

      .service-name,
      .bookmark-name {
        font-weight: 600;
      }

      .service-description,
      .bookmark-description {
        opacity: 0.82;
      }

      .service-tags {
        padding-top: 0.35rem;
        padding-right: 0.35rem;
      }

      .information-widget-search input {
        font-size: 0.95rem;
      }

      .information-widget-datetime .information-widget-label {
        letter-spacing: 0.08em;
        text-transform: uppercase;
      }

      @media (max-width: 768px) {
        body {
          background-image:
            radial-gradient(circle at top center, rgba(56, 189, 248, 0.14), transparent 18rem),
            linear-gradient(180deg, rgba(15, 23, 42, 0.98), rgba(2, 6, 23, 1));
        }

        .service-card,
        .bookmark > a,
        .widget-container {
          box-shadow: 0 10px 28px rgba(2, 6, 23, 0.22);
        }
      }
    '';
  };
}
