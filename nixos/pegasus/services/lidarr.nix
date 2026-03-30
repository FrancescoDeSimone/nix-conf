{
  config,
  pkgs,
  ...
}: {
  services.lidarr = {
    enable = true;
    openFirewall = false;
    settings.server.port = config.my.services.lidarr.port;
    user = "thinkcentre";
  };

  systemd.services.lidarr-youtube-downloader = {
    description = "Find and download missing Lidarr tracks from YouTube";
    path = with pkgs; [
      lidarr-youtube-downloader
      ffmpeg
      yt-dlp
    ];
    serviceConfig = {
      Type = "simple";
      User = "thinkcentre";
      PrivateTmp = true;
      EnvironmentFile = config.age.secrets.lidarr.path;
      StateDirectory = "lidarr-youtube-downloader";
      WorkingDirectory = "%S/lidarr-youtube-downloader";
    };
    script = ''
      export LIDARR_URL="http://localhost:${toString config.my.services.lidarr.port}"
      export LIDARR_DB="/var/lib/lidarr/lidarr.db"
      export LIDARR_MUSIC_PATH="/data/Media/Music"
      export MATCH_THRESHOLD="0.9"

      exec lyd
    '';
  };

  systemd.timers.lidarr-youtube-downloader = {
    description = "Daily Lidarr YouTube downloader sync";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "02:00";
      Persistent = true;
    };
  };
}
