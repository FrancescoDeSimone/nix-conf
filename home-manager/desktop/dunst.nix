{ config, ... }: {
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
