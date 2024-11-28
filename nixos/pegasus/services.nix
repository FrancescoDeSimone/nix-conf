{
  imports = [
    # ./services/adguard.nix
    ./services/docker.nix
    ./services/filebrowser.nix
    ./services/git.nix
    ./services/glances.nix
    #./services/homepage.nix
    ./services/jellyfin.nix
    ./services/jellyseer.nix
    # ./services/monitor.nix
    ./services/nextcloud.nix
    ./services/nginx.nix
    ./services/prowlarr.nix
    ./services/radarr.nix
    ./services/scrutiny.nix
    ./services/sonarr.nix
    ./services/stirling-pdf.nix
    ./services/transmission.nix
    # ./services/ntopng.nix
    # ./services/photoprism.nix
  ];

  services = {
    openssh.enable = true;
    smartd.enable = true;
    logrotate.enable = false;
    journald.extraConfig = "Storage=volatile";
    journald.forwardToSyslog = false;
  };
}
