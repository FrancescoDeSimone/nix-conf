{ private
, config
, pkgs
, ...
}:
let
  qbuser = private.qb.user;
  qbpasswd = private.qb.passwd;
  telegramNotifyScript = pkgs.writeShellScript "qbittorrent-telegram-notify" ''
    set -eu

    secret_file=${config.age.secrets."telegram-qbittorrent".path}
    torrent_name="''${1:-unknown}"
    content_path="''${2:-unknown}"
    category="''${3:-}"
    torrent_id="''${4:-}"

    if [ ! -r "$secret_file" ]; then
      printf '%s\n' "qBittorrent Telegram secret is not readable: $secret_file" >&2
      exit 1
    fi

    . "$secret_file"
    : "''${BOT_TOKEN:?Missing BOT_TOKEN in $secret_file}"
    : "''${CHAT_ID:?Missing CHAT_ID in $secret_file}"

    message="qBittorrent download finished on ${config.networking.hostName}
Name: $torrent_name
Path: $content_path"

    if [ -n "$category" ]; then
      message="$message
Category: $category"
    fi

    if [ -n "$torrent_id" ] && [ "$torrent_id" != "-" ]; then
      message="$message
Torrent ID: $torrent_id"
    fi

    ${pkgs.curl}/bin/curl \
      --silent \
      --show-error \
      --fail \
      --max-time 10 \
      --retry 3 \
      --data-urlencode "chat_id=$CHAT_ID" \
      --data-urlencode "text=$message" \
      "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
      > /dev/null
  '';
in
{
  services.qui = {
    enable = true;
    openFirewall = false;
    settings = {
      port = config.my.services.qui.port;
      host = "127.0.0.1";
    };
    secretFile = config.age.secrets.qui.path;
  };

  services.qbittorrent = {
    enable = true;
    user = "thinkcentre";
    group = "thinkcentre";
    profileDir = "/data/qbittorrent";
    openFirewall = false;

    serverConfig = {
      AutoRun = {
        enabled = true;
        program = ''${telegramNotifyScript} "%N" "%F" "%L" "%K"'';
      };

      LegalNotice.Accepted = true;
      Preferences = {
        WebUI = {
          Enabled = true;
          Address = "127.0.0.1";
          Port = config.my.services.qbittorrent.port;
          Username = qbuser;
          Password_PBKDF2 = qbpasswd;
          CSRFProtection = true;
          LocalHostAuth = true;
        };
        General.Locale = "en";
      };

      BitTorrent = {
        ExcludedFileNamesEnabled = true;
        Session = {
          ExcludedFileNames = builtins.concatStringsSep "\n" [
            "*.lnk" "*.zipx" "*sample.mkv" "*sample.avi" "*sample.mp4"
            "*.py" "*.vbs" "*.html" "*.php" "*.torrent"
            "*.exe" "*.bat" "*.cmd" "*.com" "*.cpl" "*.dll"
            "*.js" "*.jse" "*.msi" "*.msp" "*.pif" "*.scr"
            "*.vbe" "*.wsf" "*.wsh" "*.hta" "*.reg" "*.inf"
            "*.ps1" "*.ps2" "*.psm1" "*.psd1" "*.sh"
            "*.apk" "*.app" "*.ipa" "*.iso" "*.jar"
            "*.bin" "*.tmp" "*.vb" "*.vxd" "*.ocx" "*.drv" "*.sys"
            "*.scf" "*.ade" "*.adp" "*.bas" "*.chm" "*.crt"
            "*.hlp" "*.ins" "*.isp" "*.key" "*.mda" "*.mdb"
            "*.mdt" "*.mdw" "*.mdz" "*.potm" "*.potx" "*.ppam"
            "*.ppsx" "*.pptm" "*.sldm" "*.sldx" "*.xlam" "*.xlsb"
            "*.xlsm" "*.xltm" "*.nsh" "*.mht" "*.mhtml"
          ];
          BandwidthSchedulerEnabled = true;
          AlternativeGlobalDLSpeedLimit = 102400;
          AlternativeGlobalUPSpeedLimit = 102400;
          GlobalDLSpeedLimit = 0;
          GlobalUPSpeedLimit = 0;
          QueueingSystemEnabled = false;
          GlobalMaxRatio = -1;
          GlobalMaxSeedingMinutes = -1;
        };
      };

      Preferences.Scheduler = {
        days = 0;
        start_time = "08:00";
        end_time = "22:00";
      };
    };
  };

  users.users.thinkcentre = {
    isNormalUser = true;
    group = "thinkcentre";
  };
  users.groups.thinkcentre = { };
}
