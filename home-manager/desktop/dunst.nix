{pkgs, ...}: let
  autopause = pkgs.writeShellApplication {
    name = "dunst-autopause";
    runtimeInputs = with pkgs; [dunst pipewire gnugrep procps coreutils];
    text = ''
      state="''${XDG_RUNTIME_DIR:?}/dunst-autopause.state"
      poll=5
      sharing=0

      # pw-dump, not `pw-cli ls Node`: the latter omits media.name
      is_sharing() {
        pw-dump 2>/dev/null |
          grep -qE '"(media\.name|node\.name)": "xdp[wh]-stream'
      }

      # waybar's custom/dunst module only redraws on RTMIN+8
      refresh_bar() { pkill -RTMIN+8 waybar || true; }

      while :; do
        if is_sharing; then
          if [ "$sharing" = 0 ]; then
            sharing=1
            # only claim ownership of the pause if dunst was not already paused
            if [ "$(dunstctl is-paused 2>/dev/null)" = "false" ]; then
              : > "$state"
              dunstctl set-paused true || true
              refresh_bar
            fi
          fi
        elif [ "$sharing" = 1 ]; then
          sharing=0
          if [ -e "$state" ]; then
            dunstctl set-paused false || true
            rm -f "$state"
            refresh_bar
          fi
        fi
        sleep "$poll"
      done
    '';
  };
in {
  home.packages = [autopause];

  systemd.user.services.dunst-autopause = {
    Unit = {
      Description = "Pause dunst notifications while the screen is shared";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${autopause}/bin/dunst-autopause";
      Restart = "always";
      RestartSec = "2";
    };
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        frame_width = "1";
        markup = "yes";
        format = ''
          %s %p
          %b'';
        sort = "yes";
        indicate_hidden = "yes";
        alignment = "left";
        bounce_freq = 5;
        show_age_threshold = 60;
        word_wrap = "no";
        ignore_newline = "no";
        geometry = "0x4-25+25";
        shrink = "yes";
        transparency = 15;
        idle_threshold = 120;
        monitor = 0;
        follow = "mouse";
        sticky_history = "yes";
        history_length = 20;
        show_indicators = "yes";
        line_height = 0;
        separator_height = 1;
        padding = 8;
        horizontal_padding = 10;
        startup_notification = false;
        max_icon_size = 128;
      };
    };
  };
}
