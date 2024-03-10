{
  # virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers = {
    containers = {
      flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        ports = [ "8191:8191" ];
      };
      homer = {
        image = "b4bz/homer:latest";
        ports = [ "80:8080" ];
        volumes = [
          "/home/thinkcentre/.config/homer/config.yml/:/www/assets/config.yml"
        ];
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
      collabora = {
        image = "docker.io/collabora/code:latest";
        ports = [ "9980:9980/tcp" ];
        environment = {
          # domain = "https://nextcloud.desimedia.duckdns.org";
          extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
        };
        extraOptions = [ "--cap-add" "MKNOD" ];
      };
      # scrutiny = {
      #   image = "ghcr.io/analogj/scrutiny:master-omnibus";
      #   ports = [ "8081:8080" "8086:8086" ];
      #   volumes = [ "/run/udev:/run/udev:ro" ];
      #   extraOptions = [
      #     "--privileged"
      #     "--cap-add=SYS_RAWIO"
      #     "--device=/dev/sda"
      #     "--device=/dev/sdb"
      #     "--device=/dev/sdd"
      #   ];
      # };
    };
  };
}
