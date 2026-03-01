{ config, ... }: {
  virtualisation.oci-containers.containers.jelly-clipper = {
    image = "ghcr.io/arnolicious/jelly-clipper:latest";
    ports = [ "${toString config.my.services.jelly-clipper.port}:3000" ];
    volumes = [
      "/tmp/clips:/app/assets/videos"
    ];
    environment = {
      TZ = "Europe/Berlin";
      JELLY_CLIPPER_ORIGIN = "http://192.168.188.53:${toString config.my.services.jelly-clipper.port}";
    };
  };
}
