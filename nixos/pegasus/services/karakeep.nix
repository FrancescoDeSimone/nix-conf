{config, ...}: {
  services.karakeep = {
    enable = true;
    meilisearch.enable = true;
    browser.enable = true;
    environmentFile = config.age.secrets.hoarder.path;
    extraEnvironment = {
      PORT = toString config.my.services.karakeep.port;
    };
  };
}
