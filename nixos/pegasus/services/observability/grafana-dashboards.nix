{pkgs, ...}: let
  common = {
    datasource = {
      type = "prometheus";
      uid = "prometheus_default";
    };
    lokiDatasource = {
      type = "loki";
      uid = "loki_default";
    };
  };
  dashboards = import ./dashboards {inherit common;};
  dashboardFiles = builtins.map (name: {
    inherit name;
    path = pkgs.writeText name (builtins.toJSON dashboards.${name});
  }) (builtins.attrNames dashboards);
in {
  services.grafana.provision = {
    enable = true;
    dashboards.settings.providers = [
      {
        name = "Pegasus Dashboards";
        options.path = pkgs.linkFarm "grafana-dashboards" dashboardFiles;
      }
    ];
  };
}
