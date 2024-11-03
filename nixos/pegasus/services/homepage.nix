{
  pkgs,
  private,
  ...
}: let
  domain = private.nginx.domain;
  provider = private.nginx.provider;
  provider-statistic = private.nginx.provider-statistic;
in {
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    listenPort = 8888;
    package = pkgs.unstable.homepage-dashboard;
    settings = {};
    customCSS = "<link href=\"https://gist.githubusercontent.com/outaTiME/fa59d54f03c01a2c89c39dc6b97bf821/raw/8e4be948cd826fc1a641451c695a2422bc377f34/Fira%2520Code%2520Nerd%2520Font.css\" rel=\"stylesheet\" type=\"text/css\">";
    bookmarks = [
      {
        ${provider} = [
          {
            grafana = [
              {
                abbr = "";
                href = provider-statistic;
              }
            ];
          }
        ];
      }
    ];
    services = [
      {
        "media" = [
          {
            "jellyfin" = {
              description = "Jellyfin Media Player";
              href = "http://192.168.188.53:8096";
            };
          }
          {
            "jellyseer" = {
              description = "";
              href = "";
            };
          }
          {
            "transmission" = {
              description = "Transmission Torrent Client";
              href = "http://192.168.188.53:9091";
            };
          }
        ];
      }
      {
        "*arr" = [
          {
            "sonarr" = {
              description = "Sonarr TV Show Tracker";
              href = "http://192.168.188.53:8989";
            };
          }
          {
            "radar" = {
              description = "Radar Movie Tracker";
              href = "http://192.168.188.53:8890";
            };
          }
          {
            "prowlarr" = {
              description = "Prowlarr Index";
              href = "http://192.168.188.53:8901";
            };
          }
          {
            "lidarr" = {
              description = "Lidarr Music Tracker";
              href = "http://192.168.188.53:8899";
            };
          }
          {
            "flaresolverr" = {
              description = "";
              href = "";
            };
          }
        ];
      }
      {
        "data" = [
          {
            "duplicati" = {
              description = "Duplicati Backup System";
              href = "http://192.168.188.53:8005";
            };
          }
          {
            "nextcloud" = {
              description = "NextCloud File and Document Storage";
              href = "https://nextcloud." + domain;
            };
          }
          {
            "paperless" = {
              description = "";
              href = "";
            };
          }
          {
            "gitea" = {
              description = "";
              href = "";
            };
          }
        ];
      }
      {
        "tool" = [
          {
            "nginx-proxy-manager" = {
              description = "";
              href = "";
            };
          }
          {
            "speedtest-tracker" = {
              description = "";
              href = "";
            };
          }
          {
            "13ft" = {
              description = "";
              href = "";
            };
          }
          {
            "filebrowser " = {
              description = "";
              href = "";
            };
          }
          {
            "stirling-pdf" = {
              description = "";
              href = "";
            };
          }
          {
            "scrutiny" = {
              description = "";
              href = "";
            };
          }
          {
            "glances" = {
              description = "";
              href = "";
            };
          }
        ];
      }
    ];
    widgets = [
      {
        resources = {
          cpu = true;
          disk = "/";
          memory = true;
        };
      }
    ];
    docker = {};
  };
}
