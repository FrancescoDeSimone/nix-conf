{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    keyMode = "emacs";
    mouse = true;
    baseIndex = 1;
    customPaneNavigationAndResize = true;
    escapeTime = 0;
    sensibleOnTop = false;
    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      {
        plugin = tmuxPlugins.tilish;
        extraConfig = ''
          set -g @tilish-easymode 'on'
          set -g @tilish-default main-vertical
        '';
      }
      tmuxPlugins.catppuccin
      tmuxPlugins.sensible
    ];
    extraConfig = ''
      set-option -g status on
      set -g status-position top
      set -ga terminal-overrides ",xterm-256color:Tc"
      bind -n M-g display-popup -E "tmux new-session -A -s scratch"
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      # for yazi
      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM
    '';
  };
}
