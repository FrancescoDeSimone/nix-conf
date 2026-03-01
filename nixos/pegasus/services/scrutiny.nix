{ config, ... }: {
  services.scrutiny = {
    enable = true;
    settings.web.listen.port = config.my.services.scrutiny.port;
    openFirewall = false;
  };
}
