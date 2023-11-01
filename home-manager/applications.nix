{ pkgs, ...}:
{
  home.packages = with pkgs; [ 
    home-manager
  ];

  programs.starship = {
    enable = true;
    settings = {
      directory.fish_style_pwd_dir_length = 1; # turn on fish directory truncation
        directory.truncation_length = 2; # number of directories not to truncate
        gcloud.disabled = true; # annoying to always have on
        hostname.style = "bold green"; # don't like the default
        memory_usage.disabled = true; # because it includes cached memory it's reported as full a lot
        shlvl.disabled = false;
      username.style_user = "bold blue"; # don't like the default
    };
  };
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
    };
    enableCompletion = true;
    enableSyntaxHighlighting = true;
    enableAutosuggestions = true;
    defaultKeymap = "emacs";
    history.extended = true;
    plugins = [
    {
      name = "https://github.com/zsh-users/zsh-history-substring-search";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-history-substring-search";
        rev = "master";
        sha256 = "sha256-GSEvgvgWi1rrsgikTzDXokHTROoyPRlU0FVpAoEmXG4=";
      };
    }
    {
      name = "https://github.com/joshskidmore/zsh-fzf-history-search";
      src = pkgs.fetchFromGitHub {
        owner = "joshskidmore";
        repo = "zsh-fzf-history-search";
        rev = "master";
        sha256 = "sha256-4Dp2ehZLO83NhdBOKV0BhYFIvieaZPqiZZZtxsXWRaQ=";
      };
    }
    ];
  };

  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    keyMode = "emacs";
    escapeTime = 0;
    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.tilish
      tmuxPlugins.catppuccin
      tmuxPlugins.yank
      tmuxPlugins.sensible
      tmuxPlugins.vim-tmux-navigator
    ];
    extraConfig = ''
      set -g @tilish-easymode 'on'
      set -g base-index 1
      setw -g pane-base-index 1
      set-option -g status on
      set -g status-position top
      set-option -g mouse on
      bind -n M-g display-popup -E "tmux new-session -A -s scratch"
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      '';
  };

}
