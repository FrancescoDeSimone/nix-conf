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
    };
  };
}
