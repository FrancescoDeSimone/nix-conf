{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    jaro
  ];

  xdg.configFile."associations".text = ''
    ;; -*- mode: scheme; -*-

    (set! dynamic-menu-program "rofi -dmenu -i -p 'Open with'")

    ;; quotes \"%f\" ensure files with spaces don't break the command
    (bind
      #:pattern "image/.*"
      #:program "oculante \"%f\""
      #:on-error "sxiv \"%f\"")

    (bind
      #:pattern "video/.*"
      #:program "mpv \"%f\"")

    (bind
      #:pattern "^https?://(www\\.)?(youtube\\.com|youtu\\.be|vimeo\\.com|twitch\\.tv|odysee\\.com)/.*"
      #:program "mpv \"%f\"")

    (bind
      #:pattern "^https?://.*"
      #:program "firefox \"%f\"")

    (bind
      #:pattern "text/.*"
      #:program "foot nvim \"%f\"")

    (bind
      #:pattern "inode/directory"
      #:program "foot yazi \"%f\""
      #:tmux "tmux split-window -h \"yazi '%f'\"")

    (bind
      #:pattern ".*"
      #:program (select-one-of #:alternatives))
  '';

  home.file.".local/bin/xdg-open" = {
    source = "${pkgs.jaro}/bin/jaro";
    executable = true;
  };

  home.sessionVariables = {
    PATH = "$HOME/.local/bin:$PATH";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = ["jaro.desktop"];
      "x-scheme-handler/https" = ["jaro.desktop"];
      "text/html" = ["jaro.desktop"];
    };
  };

  xdg.desktopEntries.jaro = {
    name = "Jaro";
    genericName = "Resource Opener";
    exec = "jaro %U";
    terminal = false;
    categories = ["Utility"];
    mimeType = ["x-scheme-handler/http" "x-scheme-handler/https"];
  };
}
