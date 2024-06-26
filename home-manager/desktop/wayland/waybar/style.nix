{
  programs.waybar.style = ''
        * {
      border: none;
    	border-radius: 0;
    	font-family: "monospace";
    	font-size: 13px;
    	min-height: 0;
    	margin: 0px;
    }

    window#waybar {
    	background: rgba(0, 0, 0, 0.7);
    	color: gray;
    	color: #ffffff;
    }

    #window {
    	color: #e4e4e4;
    	font-weight: bold;
    }

    #workspaces {
    	padding: 0px;
    	margin: 0px;
    }

    #workspaces button {
    	padding: 0 2px;
    	margin: 0px;
    	background: transparent;
    	color: #ffffff;
    	font-weight: bold;
    }
    #workspaces button:hover {
    	box-shadow: inherit;
    	text-shadow: inherit;
    }

    #workspaces button.active{
    	background: #00afd7;
    	color: #1b1d1e;
    }

    #workspaces button.urgent {
    	background: #af005f;
    	color: #1b1d1e;
    }

    #mode {
    	background: #af005f;
    	color: #1b1d1e;
    }
    #clock, #battery, #cpu, #memory, #network, #pulseaudio, #custom-spotify, #tray, #mode {
    	padding: 0 3px;
    	margin: 0 2px;
    }

    #clock {
    }

    #battery {
    }

    #battery icon {
        color: red;
    }

    #battery.charging {
    }

    @keyframes blink {
        to {
            background-color: #af005f;
        }
    }

    #battery.warning:not(.charging) {
    	background-color: #ff8700;
    	color: #1b1d1e;
    }
    #battery.critical:not(.charging) {
        color: white;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
    }

    #cpu {
    }

    #memory {
    }

    #network {
    }

    #network.disconnected {
        background: #f53c3c;
    }

    #pulseaudio {
    }

    #pulseaudio.muted {
    }

    #tray {
    }


  '';
}
