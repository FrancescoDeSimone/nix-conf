{ config, ... }: {
  virtualisation.oci-containers.containers.speedtesttracker = {
    image = "henrywhitaker3/speedtest-tracker";
    ports = [ "${toString config.my.services.speedtesttracker.port}:80" ];
    environment = { OOKLA_EULA_GDPR = "true"; };
  };
}
