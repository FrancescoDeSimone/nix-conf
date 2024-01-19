{ pkgs, lib, inputs, config, ... }: {
  programs.tmux = {
    enable = true;
    #terminal = "screen-256color";
    keyMode = "emacs";
    escapeTime = 0;
    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.tilish
      tmuxPlugins.catppuccin
      tmuxPlugins.yank
      tmuxPlugins.sensible
    ];
    extraConfig = ''
      set -g @tilish-easymode 'on'
      set -g base-index 1
      setw -g pane-base-index 1
      set-option -g status on
      set -g status-position top
      set-option -g mouse on
      set -ga terminal-overrides ",xterm-256color:Tc"
      bind -n M-g display-popup -E "tmux new-session -A -s scratch"
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
    '';
  };
}
