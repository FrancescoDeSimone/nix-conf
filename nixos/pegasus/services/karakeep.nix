{config, pkgs, ...}: {
  services.karakeep = {
    enable = true;
    package = pkgs.unstable.karakeep;
    meilisearch.enable = true;
    browser.enable = true;
    environmentFile = config.age.secrets.hoarder.path;
    extraEnvironment = {
      PORT = toString config.my.services.karakeep.port;
    };
  };
}
