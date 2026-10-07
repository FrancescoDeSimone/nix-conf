{
  config,
  pkgs,
  private,
  ...
}: let
  gitUiInstance = "git-ui";
  gitUpstream = "http://192.168.200.11:${toString config.my.services.git.port}";
  gitRuntimeDir = "/run/anubis/anubis-${gitUiInstance}";
  pdfUiInstance = "pdf-ui";
  pdfUpstream = "http://127.0.0.1:${toString config.my.services.stirling-pdf.port}";
  pdfRuntimeDir = "/run/anubis/anubis-${pdfUiInstance}";
  microbinUiInstance = "microbin-ui";
  microbinUpstream = "http://192.168.104.11:${toString config.my.services.microbin.port}";
  microbinRuntimeDir = "/run/anubis/anubis-${microbinUiInstance}";
  bypassUiInstance = "bypass-ui";
  bypassUpstream = "http://127.0.0.1:${toString config.my.services.bypass.port}";
  bypassRuntimeDir = "/run/anubis/anubis-${bypassUiInstance}";
  itToolsUiInstance = "it-tools-ui";
  itToolsUpstream = "http://127.0.0.1:${toString config.my.services.it-tools.port}";
  itToolsRuntimeDir = "/run/anubis/anubis-${itToolsUiInstance}";
in {
  services.anubis = {
    package = pkgs.anubis;
    defaultOptions = {
      user = "anubis";
      group = "anubis";
      extraFlags = [];
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

    instances.${pdfUiInstance}.settings = {
      TARGET = pdfUpstream;
      BIND = "${pdfRuntimeDir}/anubis.sock";
      METRICS_BIND = "${pdfRuntimeDir}/anubis-metrics.sock";
    };

    instances.${microbinUiInstance}.settings = {
      TARGET = microbinUpstream;
      BIND = "${microbinRuntimeDir}/anubis.sock";
      METRICS_BIND = "${microbinRuntimeDir}/anubis-metrics.sock";
    };

    instances.${bypassUiInstance}.settings = {
      TARGET = bypassUpstream;
      BIND = "${bypassRuntimeDir}/anubis.sock";
      METRICS_BIND = "${bypassRuntimeDir}/anubis-metrics.sock";
    };

    instances.${itToolsUiInstance}.settings = {
      TARGET = itToolsUpstream;
      BIND = "${itToolsRuntimeDir}/anubis.sock";
      METRICS_BIND = "${itToolsRuntimeDir}/anubis-metrics.sock";
    };
  };

  users.users.nginx.extraGroups = [config.services.anubis.defaultOptions.group];
}
