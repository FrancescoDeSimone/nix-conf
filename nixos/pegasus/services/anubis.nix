{
  config,
  pkgs,
  private,
  ...
}:
let
  gitUiInstance = "git-ui";
  gitUpstream = "http://192.168.200.11:${toString config.my.services.git.port}";
  gitRuntimeDir = "/run/anubis/anubis-${gitUiInstance}";
in
{
  services.anubis = {
    package = pkgs.anubis;
    defaultOptions = {
      user = "anubis";
      group = "anubis";
      extraFlags = [ ];
      botPolicy = null;
      settings = {
        BIND_NETWORK = "unix";
        METRICS_BIND_NETWORK = "unix";
        DIFFICULTY = 4;
        SERVE_ROBOTS_TXT = true;
        OG_PASSTHROUGH = true;
        WEBMASTER_EMAIL = private.nginx.email;
      };
    };

    instances.${gitUiInstance}.settings = {
      TARGET = gitUpstream;
      BIND = "${gitRuntimeDir}/anubis.sock";
      METRICS_BIND = "${gitRuntimeDir}/anubis-metrics.sock";
    };
  };

  users.users.nginx.extraGroups = [ config.services.anubis.defaultOptions.group ];
}
