{
  services.scrutiny = {
    enable = true;
    settings.web.listen.port = 8081;
    openFirewall = true;
  };
}
