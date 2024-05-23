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
      deemix = {
        image = "registry.gitlab.com/bockiii/deemix-docker";
        ports = [ "6595:6595" ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          UMASK_SET = "22";
          DEEMIX_SINGLE_USER = "true";
        };
        volumes = [
          "/data/Media/Music/deemix:/downloads"
          "/home/thinkcentre/.config/deemix:/config"
        ];
      };
    };

  };
}
