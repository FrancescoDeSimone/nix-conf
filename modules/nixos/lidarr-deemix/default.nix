{config, lib, pkgs, ...}: let
  cfg = config.my.services.lidarr-deemix;
in {
  options.my.services.lidarr-deemix = {
    enable = lib.mkEnableOption "Deemix integration for stock Lidarr (like lidarr-on-steroids without the fork)";

    deemixUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:${toString config.my.services.deemix.port}";
      description = "Deemix WebUI URL (from my.services.deemix).";
    };

    lidarrDataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/lidarr/.config/Lidarr";
      description = "Lidarr data dir where plugins live.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.lidarr-deemix-setup = {
      description = "Install Deemix plugin for Lidarr (like lidarr-on-steroids)";
      before = ["lidarr.service"];
      wantedBy = ["lidarr.service"];
      after = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "thinkcentre";
        Group = "lidarr";
      };
      script = ''
        set -euo pipefail
        pluginDir="${cfg.lidarrDataDir}/plugins/Deemix"
        mkdir -p "$pluginDir"
        if [[ ! -f "$pluginDir/Lidarr.Plugin.Deemix.dll" ]]; then
          echo "Fetching Lidarr.Plugin.Deemix..."
          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT
          ${pkgs.curl}/bin/curl -L -o "$tmp/deemix.zip" "https://github.com/ta264/Lidarr.Plugin.Deemix/releases/download/v1.3.0.65/Lidarr.Plugin.Deemix.net8.0.zip" || true
          if [[ -s "$tmp/deemix.zip" ]]; then
            ${pkgs.unzip}/bin/unzip -o "$tmp/deemix.zip" -d "$pluginDir"
            chown -R thinkcentre:lidarr "$pluginDir"
            chmod 0644 "$pluginDir"/*.dll 2>/dev/null || true
            echo "Deemix plugin installed to $pluginDir"
          else
            echo "No prebuilt Deemix plugin found — Lidarr will run without it. Use Deemixrr or custom script fallback."
          fi
        fi

        # Ensure lidarr-flac2mp3 script is linked for Custom Script conversion (like lidarr-on-steroids)
        if [[ -f "${pkgs.lidarr-flac2mp3 or pkgs.writeText "x" ""}" ]]; then
          echo "lidarr-flac2mp3 available at ${pkgs.writeShellScript "flac2custom" "exec ${pkgs.bash}/bin/bash ${pkgs.lidarr-flac2mp3 or ""}/bin/flac2custom.sh \"$@\""}"
        fi
        echo "Configure Lidarr WebUI → Settings → Indexers → Deemix → URL ${cfg.deemixUrl} + ARL from /var/lib/deemix/login.json"
        echo "And Settings → Download Clients → Deemix → same URL. Music will land in ${config.my.services.deemix.musicDir} (0775 thinkcentre:deemix, readable by Jellyfin thinkcentre:jellyfin)."
      '';
    };

    systemd.services.lidarr = {
      after = ["lidarr-deemix-setup.service"];
      requires = ["lidarr-deemix-setup.service"];
    };
  };
}
