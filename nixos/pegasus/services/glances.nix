{ config, ... }: {
  services.glances = {
    enable = true;
    openFirewall = false;
    port = config.my.services.glances.port;
    extraArgs = [ "--export" "prometheus" ];
  };
}
