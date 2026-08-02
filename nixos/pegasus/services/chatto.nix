{
  config,
  private,
  ...
}: {
  imports = [../../../modules/nixos/chatto];

  my.services.chatto = {
    enable = true;
    url = "https://chatto.${private.nginx.internalDomain}";
    serverName = "Chatto";
    owners = ["admin@lan64.de"];
    trustedProxies = ["192.168.80.10/32"];
    bootstrapUsers = [
      {
        login = "thinkcentre";
        email = "admin@lan64.de";
        displayName = "Admin";
        serverRole = "owner";
        passwordFile = config.age.secrets."chatto-admin".path;
      }
    ];
    video.enable = true;
    search.enable = true;
    metrics.enable = true;
    operatorApi.enable = true;
  };
}
