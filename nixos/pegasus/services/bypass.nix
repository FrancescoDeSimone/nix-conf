{ config, ... }: {
  virtualisation.oci-containers.containers.bypass = {
    image = "wasimaster/13ft";
    ports = [ "${toString config.my.services.bypass.port}:5000" ];
  };
}
