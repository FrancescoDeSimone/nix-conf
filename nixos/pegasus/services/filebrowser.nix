{
  systemd.services.filebrowser = {
    enable = true;
    wantedBy = [ "default.target" ];
    serviceConfig = {
      User = "root";
      Group = "wheel";
      ExecStart = "/run/current-system/sw/bin/filebrowser --database /var/lib/filebrowser/filebrowser.db --address 0.0.0.0 -p 8082";
    };
  };
}
