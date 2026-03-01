{
  pkgs,
  config,
  private,
  lib,
  ...
}: let
  domain = private.nginx.domain;
  provider = private.nginx.provider;
  provider-statistic = private.nginx.provider-statistic;

  capitalize = s:
    if (builtins.stringLength s) > 0
    then (lib.toUpper (builtins.substring 0 1 s)) + (builtins.substring 1 (builtins.stringLength s) s)
    else s;

  lanHosts = lib.filterAttrs (name: _: lib.hasSuffix ".pegasus.lan" name) config.services.nginx.virtualHosts;

  autoServiceList =
    lib.mapAttrsToList
    (
      host: _: let
        name = lib.removeSuffix ".pegasus.lan" host;
        displayName = capitalize name;
      in {
        "${displayName}" = {
          href = "http://${host}";
          description = "${displayName} Service";
        };
      }
    )
    lanHosts;
in {
  systemd.services.homepage-dashboard.environment = {
    HOMEPAGE_ALLOWED_HOSTS = lib.mkForce "homepage.pegasus.lan";
  };

  services.homepage-dashboard = {
    enable = true;
    openFirewall = false;
    listenPort = config.my.services.homepage.port;
    package = pkgs.unstable.homepage-dashboard;

    services = [
      {
        "My Services" = autoServiceList;
      }
    ];

    bookmarks = [
      {
        ${provider} = [
          {
            grafana = [
              {
                abbr = "";
                href = provider-statistic;
              }
            ];
          }
        ];
      }
    ];

    widgets = [
      {
        resources = {
          cpu = true;
          disk = "/";
          memory = true;
        };
      }
    ];

    customCSS = "<link href=\"https://gist.githubusercontent.com/outaTiME/fa59d54f03c01a2c89c39dc6b97bf821/raw/8e4be948cd826fc1a641451c695a2422bc377f34/Fira%2520Code%2520Nerd%2520Font.css\" rel=\"stylesheet\" type=\"text/css\">";
  };
}
