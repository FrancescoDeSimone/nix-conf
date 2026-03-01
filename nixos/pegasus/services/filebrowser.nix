{ config, ... }: {
  services.filebrowser = {
    enable = true;
    user = "root";
    group = "wheel";
    settings = {
      database = "/var/lib/filebrowser/filebrowser.db";
      root = "/";
      port = config.my.services.filebrowser.port;
    };
    openFirewall = false;
  };
}
