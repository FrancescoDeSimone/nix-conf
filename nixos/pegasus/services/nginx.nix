{
  config,
  private,
  ...
}: let
  email = private.nginx.email;
  domain = private.nginx.domain;
  provider = private.nginx.provider;
in {
  security.acme = {
    acceptTerms = true;
    preliminarySelfsigned = true;
    defaults.email = email;
    certs.${domain} = {
      domain = "*." + domain;
      dnsProvider = provider;
      #server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      group = "nginx";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = false;
      environmentFile = config.age.secrets.provider.path;
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts.${"nextcloud." + domain} = {
      forceSSL = true;
      useACMEHost = domain;
      locations."/".proxyPass = "http://192.168.100.10:8010";
    };
    virtualHosts.${"jellyfin." + domain} = {
      forceSSL = true;
      useACMEHost = domain;
      locations."/".proxyPass = "http://127.0.0.1:8096";
    };
    virtualHosts.${"pdf." + domain} = {
      forceSSL = true;
      useACMEHost = domain;
      locations."/".proxyPass = "http://127.0.0.1:8080";
    };
    virtualHosts.${"bypass." + domain} = {
      forceSSL = true;
      useACMEHost = domain;
      locations."/".proxyPass = "http://127.0.0.1:5000";
    };
    virtualHosts.${"jellyseer." + domain} = {
      forceSSL = true;
      useACMEHost = domain;
      locations."/".proxyPass = "http://127.0.0.1:5055";
    };
    virtualHosts.${"git." + domain} = {
      forceSSL = true;
      useACMEHost = domain;
      locations."/".proxyPass = "http://192.168.200.11:3001";
    };
  };

  networking.firewall = {
    enable = false;
    # allowedTCPPorts = [80 443 22];
  };
}
