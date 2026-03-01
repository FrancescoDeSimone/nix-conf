{ config, ... }: {
  virtualisation.oci-containers.containers.flaresolverr = {
    image = "ghcr.io/flaresolverr/flaresolverr:latest";
    ports = [ "${toString config.my.services.flaresolverr.port}:8191" ];
  };
}
