{
  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers = {
    containers = {
      flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        ports = ["8191:8191"];
      };
      speedtesttracker = {
        image = "henrywhitaker3/speedtest-tracker";
        ports = ["8765:80"];
        environment = {OOKLA_EULA_GDPR = "true";};
      };
      bypass = {
        image = "wasimaster/13ft";
        ports = ["5000:5000"];
      };
      lidarr-on-steroids = {
        image = "youegraillot/lidarr-on-steroids";
        ports = ["8686:8686" "6595:6595"];
        environment = {
          CLEAN_DOWNLOADS = "true";
          AUTOCONFIG = "true";
        };
        volumes = [
          "/home/thinkcentre/.config/lidarr-on-steroids/lidarr:/config"
          "/home/thinkcentre/.config/lidarr-on-steroids/deemix:/config_deemix"
          "/data/Media/Music/:/music"
        ];
      };
    };
  };
}
