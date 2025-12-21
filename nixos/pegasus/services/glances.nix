{
  systemd.services.glances = {
    enable = true;
    wantedBy = [ "default.target" ];
    serviceConfig = {
      User = "thinkcentre";
      Group = "users";
      ExecStart = "/run/current-system/sw/bin/glances -w";
    };
  };
}
