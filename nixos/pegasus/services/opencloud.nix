{
  pkgs,
  lib,
  private,
  ...
}: let
  domain = private.nginx.domain;
in {
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-opencloud"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  containers.opencloud = {
    #bindMounts = {
    #  "/var/lib/opencloud" = {
    #    hostPath = "/nextcloud";
    #    isReadOnly = false;
    #  };
    #};
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.103.10";
    localAddress = "192.168.103.11";
    config = {
      config,
      pkgs,
      ...
    }: {
      system.stateVersion = "25.11";
      services.opencloud = {
        settings.token_manager.jwt_secret = "9a3e8f13bc2109f3bee15a8373ed46e6";
        enable = true;
        #stateDir = "/var/lib/opencloud";
        user = "opencloud";
        group = "opencloud";
        address = "0.0.0.0";
        port = 8080;
        url = "http://opencloud.pegasus.lan";
        environment = {
          "OC_INSECURE" = "true"; # Matches the doc you found
          "OCIS_HTTP_TLS_ENABLED" = "false"; # Explicitly disables TLS on the http server
          "PROXY_HTTP_ADDR" = "0.0.0.0:8080"; # Ensures the proxy service binds correctly
        };
      };

      networking.firewall = {
        enable = false;
        allowedTCPPorts = [80 443 8080];
      };
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };
}
