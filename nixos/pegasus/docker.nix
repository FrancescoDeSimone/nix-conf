{
  # virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers = {
    containers = {
      flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        ports = [ "8191:8191" ];
      };
      nginxproxymanager = {
        image = "jc21/nginx-proxy-manager:latest";
        ports = [ "81:81" "443:443" ];
        volumes = [
          "/home/thinkcentre/.config/npm/data:/data"
          "/home/thinkcentre/.config/npm/letsencrypt:/etc/letsencrypt"
        ];
      };
      speedtesttracker = {
        image = "henrywhitaker3/speedtest-tracker";
        ports = [ "8765:80" ];
        environment = { OOKLA_EULA_GDPR = "true"; };
      };
      Stirling-PDF = {
        image = "frooodle/s-pdf:latest";
        ports = [ "8080:8080" ];
      };
      lidarr-on-steroids = {
        image = "youegraillot/lidarr-on-steroids";
        ports = [ "8686:8686" "6595:6595" ];
        environment = {
          CLEAN_DOWNLOADS = "true";
          AUTOCONFIG = "true";
        };
        volumes = [
          "/home/thinkcentre/.config/lidaar-on-steroids/lidaar:/config"
          "/home/thinkcentre/.config/lidaar-on-steroids/deemix:/config_deemix"
          "/data/Media/Music/:/music"
        ];
      };
    };

  };
}
