{ pkgs, lib, inputs, config, ... }:
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
      dd="dd status=progress";
      tb="nc termbin.com 9999";
      fd="fd -j12";
      drag="dragon";
      drop="dragon -t";
      aringa="| curl -LF \"aringa=<-\" --post301 arin.ga";
    };
    enableCompletion = true;
    enableSyntaxHighlighting = true;
    enableAutosuggestions = true;
    defaultKeymap = "emacs";
    history.extended = true;
    plugins = [
    {
      name = "zsh-history-substring-search";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-history-substring-search";
        rev = "master";
        sha256 = "sha256-GSEvgvgWi1rrsgikTzDXokHTROoyPRlU0FVpAoEmXG4=";
      };
    }
    {
      name = "zsh-fzf-history-search";
      src = pkgs.fetchFromGitHub {
        owner = "joshskidmore";
        repo = "zsh-fzf-history-search";
        rev = "master";
        sha256 = "sha256-4Dp2ehZLO83NhdBOKV0BhYFIvieaZPqiZZZtxsXWRaQ=";
      };
    }
    ];
    initExtra = ''
      bindkey '^[[1;5C' forward-word # Ctrl+RightArrow
      bindkey '^[[1;5D' backward-word # Ctrl+LeftArrow
      ZSH_FZF_HISTORY_SEARCH_FZF_ARGS="+s +m -x -e --height 40%  --height 20%  --layout reverse --info inline"

      zstyle ':completion:*' completer _complete _match _approximate
      zstyle ':completion:*:match:*' original only
      zstyle ':completion:*:approximate:*' max-errors 1 numeric
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      '';
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

  programs.htop = {
    enable = true;
    settings = {
      fields = with config.lib.htop.fields; [
        PID
        USER
        PERCENT_CPU
        PERCENT_MEM
        COMM
      ];
      hide_kernel_threads = 0;
      hide_userland_threads = 0;
      shadow_other_users = 0;
      show_thread_names = 0;
      show_program_path = 0;
      highlight_base_name = 1;
      highlight_deleted_exe = 1;
      highlight_megabytes = 1;
      highlight_threads = 1;
      highlight_changes = 0;
      highlight_changes_delay_secs = 5;
      find_comm_in_cmdline = 1;
      strip_exe_from_cmdline = 1;
      show_merged_command = 0;
      header_margin = 1;
      screen_tabs = 1;
      detailed_cpu_time = 1;
      cpu_count_from_one = 1;
      show_cpu_usage = 1;
      show_cpu_frequency = 0;
      show_cpu_temperature = 0;
      degree_fahrenheit = 0;
      update_process_names = 1;
      account_guest_in_cpu_meter = 1;
      enable_mouse = 1;
      delay = 15;
      hide_function_bar = 0;
      header_layout = "four_25_25_25_25";
      column_meters_0 = "Hostname Date Uptime";
      column_meter_modes_0 = "2 2 2";
      column_meters_1 = "LeftCPUs2";
      column_meter_modes_1 = 1;
      column_meters_2 = "RightCPUs2";
      column_meter_modes_2 = 1;
      column_meters_3 = "Memory Swap Battery";
      column_meter_modes_3 = "1 1 1";
      tree_view = 0;
      sort_key = 46;
      tree_sort_key = 0;
      sort_direction = -1;
      tree_sort_direction = 1;
      tree_view_always_by_pid = 1;
      all_branches_collapsed = 0;
    };
  };

}
