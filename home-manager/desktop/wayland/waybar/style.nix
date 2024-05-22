{
  programs.waybar.style = ''
    @define-color foreground #CEDCE8;
    @define-color background rgba(1,1,1,0.25);
    @define-color cursor #CEDCE8;

    @define-color color0 #010101;
    @define-color color1 #080B0D;
    @define-color color2 #1F2739;
    @define-color color3 #273541;
    @define-color color4 #354262;
    @define-color color5 #41586B;
    @define-color color6 #56738E;
    @define-color color7 #B0C4D6;
    @define-color color8 #7B8995;
    @define-color color9 #0B0E11;
    @define-color color10 #2A344C;
    @define-color color11 #344656;
    @define-color color12 #475882;
    @define-color color13 #57758F;
    @define-color color14 #729ABD;
    @define-color color15 #B0C4D6;
        * {
        font-family: "JetBrainsMono Nerd Font";
        font-weight: bold;
        min-height: 0;
        /* set font-size to 100% if font scaling is set to 1.00 using nwg-look */
        font-size: 97%;
        font-feature-settings: '"zero", "ss01", "ss02", "ss03", "ss04", "ss05", "cv31"';
        padding: 1px;
        }

        window#waybar {
            background: black;
        }

        window#waybar.hidden {
            opacity: 0.5;
        }

        window#waybar.empty {
            background-color: transparent;
        }

        window#waybar.empty #window {
            padding: 0px;
            border: 0px;
            /*  background-color: rgba(66,66,66,0.5); */ /* transparent */
            background-color: transparent;
        }

        tooltip {
          color: @foreground;
            background: rgba(0, 0, 0, 0.8);
        }

        tooltip label {
            color: @foreground;
            padding-right: 2px;
            padding-left: 2px;
        }

        /*-----module groups----*/
        .modules-right {
            border: 0px solid #b4befe;
          padding-top: 2px;
          padding-bottom: 2px;
            padding-right: 4px;
            padding-left: 4px;
        }

        .modules-center {
            border: 0px solid #b4befe;
          padding-top: 2px;
          padding-bottom: 2px;
            padding-right: 4px;
            padding-left: 4px;
        }

        .modules-left {
            border: 0px solid #b4befe;
          padding-top: 2px;
          padding-bottom: 2px;
            padding-right: 4px;
            padding-left: 4px;    
        }

        #workspaces button {
            color: @color12;
            box-shadow: none;
          text-shadow: none;
            padding: 0px;
            padding-left: 4px;
            padding-right: 4px;
            animation: gradient_f 20s ease-in infinite;
            transition: all 0.5s cubic-bezier(.55,-0.68,.48,1.682);
        }

        #workspaces button.active {
            color: @foreground;
            padding-left: 8px;
            padding-right: 8px;
            animation: gradient_f 20s ease-in infinite;
            transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
        }

        #workspaces button.focused {
            color: #d8dee9;
        }

        #workspaces button.urgent {
            color: #11111b;
        }

        #workspaces button:hover {
            color: #9CCFD8;
          padding-left: 2px;
            padding-right: 2px;
            animation: gradient_f 20s ease-in infinite;
            transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
        }

        #backlight,
        #backlight-slider,
        #battery,
        #bluetooth,
        #clock,
        #cpu,
        #disk,
        #idle_inhibitor,
        #keyboard-state,
        #memory,
        #mode,
        #mpris,
        #network,
        #pulseaudio,
        #pulseaudio-slider,
        #taskbar,
        #temperature,
        #tray,
        #window,
        #wireplumber,
        #workspaces,
        #custom-backlight,
        #custom-cava_mviz,
        #custom-cycle_wall,
        #custom-hint,
        #custom-keyboard,
        #custom-light_dark,
        #custom-lock,
        #custom-menu,
        #custom-power_vertical,
        #custom-power,
        #custom-swaync,
        #custom-updater,
        #custom-weather,
        #custom-weather.clearNight,
        #custom-weather.cloudyFoggyDay,
        #custom-weather.cloudyFoggyNight,
        #custom-weather.default, 
        #custom-weather.rainyDay,
        #custom-weather.rainyNight,
        #custom-weather.severe,
        #custom-weather.showyIcyDay,
        #custom-weather.snowyIcyNight,
        #custom-weather.sunnyDay {
            color: @foreground;
          padding-top: 3px;
          padding-bottom: 3px;
          padding-right: 6px;
          padding-left: 6px;
        }

        #temperature.critical {
            background-color: #ff0000;
        }

        @keyframes blink {
            to {
                color: #000000;
            }
        }

        #taskbar button.active {
            background-color: #7f849c;
            padding-left: 12px;
            padding-right: 12px;
            animation: gradient_f 20s ease-in infinite;
            transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
        }

        #taskbar button:hover {
            padding-left: 3px;
            padding-right: 3px;
            animation: gradient_f 20s ease-in infinite;
            transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
        }

        #battery.critical:not(.charging) {
            color: #f53c3c;
            animation-name: blink;
            animation-duration: 0.5s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
        }
        #pulseaudio-slider slider {
          min-width: 0px;
          min-height: 0px;
          opacity: 0;
          background-image: none;
          border: none;
          box-shadow: none;
        }

        #pulseaudio-slider trough {
          min-width: 80px;
          min-height: 5px;
        }

        #pulseaudio-slider highlight {
          min-height: 10px;
        }

        #backlight-slider slider {
          min-width: 0px;
          min-height: 0px;
          opacity: 0;
          background-image: none;
          border: none;
          box-shadow: none;
        }

        #backlight-slider trough {
          min-width: 80px;
          min-height: 10px;
        }

        #backlight-slider highlight {
          min-width: 10px;
        }
  '';
}
