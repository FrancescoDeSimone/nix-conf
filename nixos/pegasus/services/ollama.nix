{ pkgs
, config
, ...
}: {
  services.ollama = {
    enable = true;
    package = pkgs.unstable.ollama;
    host = "127.0.0.1";
    port = config.my.services.ollama.port;
    openFirewall = false;
  };
}
