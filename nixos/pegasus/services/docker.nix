{
  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers = {
    containers = {
      flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        ports = ["8191:8191"];
      };
      speedtesttracker = {
        image = "henrywhitaker3/speedtest-tracker";
        ports = ["8765:80"];
        environment = {OOKLA_EULA_GDPR = "true";};
      };
      jelly-clipper = {
        image = "ghcr.io/arnolicious/jelly-clipper:latest";
        ports = ["3333:3000"];
        volumes = [
          "/tmp/clips:/app/assets/videos"
        ];
        environment = {
          TZ = "Europe/Berlin";
          JELLY_CLIPPER_ORIGIN = "http://192.168.188.53:3333";
        };
      };
      wealthfolio = {
        image = "afadil/wealthfolio:latest";
        ports = ["8088:8088"];
        environment = {
          WF_LISTEN_ADDR = "0.0.0.0:8088";
          WF_SECRET_KEY = "CHzDJP0GRuPjyBUSZsAVo0GDw8GTSSAFOw/ofxvQ7zI=";
          WF_DB_PATH = "/data/wealthfolio.db";
        };
      };
      bypass = {
        image = "wasimaster/13ft";
        ports = ["5000:5000"];
      };
    };
  };
}
