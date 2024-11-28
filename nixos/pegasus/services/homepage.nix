{
  pkgs,
  config,
  private,
  ...
}: let
  domain = private.nginx.domain;
  provider = private.nginx.provider;
  provider-statistic = private.nginx.provider-statistic;

  servicesList = builtins.map (
    name: let
      service = config.services.${name};
    in
      if builtins.hasAttr "enable" service
      then {
        name = name;
        value = service;
      }
      else null
  ) (builtins.attrNames config.services);

  validServices = builtins.filter (service: service != null) servicesList;

  enabledServices = builtins.filter (service: service.value.enable == true) validServices;

  services =
    builtins.map (service: {
      name = service.name;
      enable = service.value.enable;
      port = service.value.port or null;
    })
    enabledServices;

  homepageDashboardServices = builtins.concatLists (
    builtins.map (service: [
      {
        "My First Group" = [
          {
            "My First Service" = {
              description = "Homepage is awesome";
              href = "http://localhost/";
            };
          }
        ];
      }
    ])
    services
  );
in {
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    listenPort = 8888;
    package = pkgs.unstable.homepage-dashboard;
    settings = {};
    customCSS = "<link href=\"https://gist.githubusercontent.com/outaTiME/fa59d54f03c01a2c89c39dc6b97bf821/raw/8e4be948cd826fc1a641451c695a2422bc377f34/Fira%2520Code%2520Nerd%2520Font.css\" rel=\"stylesheet\" type=\"text/css\">";
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
    services = homepageDashboardServices;
    widgets = [
      {
        resources = {
          cpu = true;
          disk = "/";
          memory = true;
        };
      }
    ];
    docker = {};
  };
}
