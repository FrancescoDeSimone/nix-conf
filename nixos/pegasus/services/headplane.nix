{
  config,
  pkgs,
  ...
}: let
  headplaneDataPath = "/var/lib/headplane";
  headplaneCookieSecretPath = "${headplaneDataPath}/cookie_secret";
in {
  services.headplane = {
    enable = true;
    package = pkgs.unstable.headplane;
    agent.package = pkgs.unstable.headplane-agent;

    settings = {
      server = {
        host = "127.0.0.1";
        port = config.my.services.headplane.port;
        data_path = headplaneDataPath;
        cookie_secret_path = headplaneCookieSecretPath;
        cookie_secure = false;
      };

      headscale = {
        url = "http://127.0.0.1:${toString config.my.services.headscale.port}";
        public_url = config.services.headscale.settings.server_url;
        config_path = null;
        config_strict = false;
      };
    };
  };

  systemd.services.headplane.preStart = ''
    umask 077
    rm -f ${headplaneCookieSecretPath}
    head -c 32 < ${config.age.secrets."headplane-cookie-secret".path} > ${headplaneCookieSecretPath}

    if [ "$(wc -c < ${headplaneCookieSecretPath})" -ne 32 ]; then
      echo "headplane cookie secret must yield exactly 32 characters" >&2
      exit 1
    fi
  '';
}
