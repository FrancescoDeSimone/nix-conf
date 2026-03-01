{
  imports = [
    ./services/ports.nix
    ./services/observability.nix
    ./services/docker.nix
    ./services/filebrowser.nix
    ./services/git.nix
    ./services/glances.nix
    ./services/homepage.nix
    ./services/jellyfin.nix
    ./services/jellyseer.nix
    ./services/nextcloud.nix
    ./services/nginx.nix
    ./services/prowlarr.nix
    ./services/govd.nix
    ./services/radarr.nix
    ./services/scrutiny.nix
    ./services/sonarr.nix
    ./services/stirling-pdf.nix
    ./services/qbittorrent.nix
    ./services/ollama.nix
    ./services/hoarder.nix
    ./services/flaresolverr.nix
    ./services/speedtesttracker.nix
    # ./services/jelly-clipper.nix
    ./services/bypass.nix
  ];

  services = {
    openssh.enable = true;
    smartd.enable = true;
    logrotate.enable = false;
    journald.extraConfig = "Storage=volatile";
    journald.forwardToSyslog = false;
  };
}
