{
  systemd.services.it-tools = {
    enable = true;
    wantedBy = ["default.target"];
    serviceConfig = {
      User = "root";
      Group = "wheel";
      ExecStart = "/run/current-system/sw/bin/it-tools";
    };
  };
}
