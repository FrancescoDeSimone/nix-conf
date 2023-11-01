{
  networking.firewall.enable = false;
  services.openssh.enable = true;
  services.smartd.enable = true;

  services.sonarr = {
    enable = true;
    openFirewall = true;
    user = "thinkcentre";
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
    user = "thinkcentre";
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

#services.navidrome = {
#  enable = true;
#  settings = {
#    MusicFolder = "/data/Media/Music/";
#    Address = "0.0.0.0";
#    Port = 4533;
#  };
#};

  services.lidarr= {
    enable = true;
    openFirewall = true;
    user = "thinkcentre";
  };

#services.gogs = {
#  enable = true;
#};

#services.duplicati = {
#  #package =duplicati;
#  enable = true;
#  interface = "any";
#};

#services.transmission = {
#  enable = true;
#  openRPCPort = true;
#  openFirewall = true;
#  user = "desi";
#  settings = {
#    rpc-bind-address="0.0.0.0";
#    rpc-whitelist-enabled = false;
#    home = "/disk2/transmission";
#    download-dir = "/disk2/transmission/Downloads";
#    incomplete-dir = "/disk2/transmission/.incomplete";
#    watch-dir = "/disk2/transmission/watchdir";
#    alt-speed-time-enabled = true;
#    alt-speed-time-end = 1410;
#  };
#};

  services.jellyseerr = {
    enable = true;
    openFirewall = true;
  };

  systemd.services.glances = {
    enable = true;
    wantedBy = ["default.target"];
    serviceConfig = {
      User="thinkcentre";
      Group="users";  
      ExecStart = "/run/current-system/sw/bin/glances -w";
    };
  };

  systemd.services.yarr = {
    enable = true;
    wantedBy = ["default.target"];
    serviceConfig = {
      User="thinkcentre";
      Group="users";  
      ExecStart = "/run/current-system/sw/bin/yarr -addr 0.0.0.0:7070";
    };
  };
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "thinkcentre";
  };

  systemd.services.filebrowser = {
    enable = true;
    wantedBy = ["default.target"];
    serviceConfig = {
      User="root";
      Group="wheel";  
      ExecStart = "/run/current-system/sw/bin/filebrowser --database /var/lib/filebrowser/filebrowser.db --address 0.0.0.0 -p 8080";
    };
  };
}
