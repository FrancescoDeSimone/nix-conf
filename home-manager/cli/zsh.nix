{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -larth";
      dd = "dd status=progress";
      tb = "nc termbin.com 9999";
      fd = "fd -j12";
      drag = "dragon";
      drop = "dragon -t";
      aringa = ''| curl -LF "aringa=<-" --post301 arin.ga'';
    };
    enableCompletion = true;
    syntaxHighlighting.enable = true;
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
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "master";
          sha256 = "sha256-B+Kz3B7d97CM/3ztpQyVkE6EfMipVF8Y4HJNfSRXHtU=";
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
      autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      [[ -n "''${key[Up]}"   ]] && bindkey -- "''${key[Up]}"   up-line-or-beginning-search
      [[ -n "''${key[Down]}" ]] && bindkey -- "''${key[Down]}" down-line-or-beginning-search



      bindkey '^[[1;5C' forward-word # Ctrl+RightArrow
      bindkey '^[[1;5D' backward-word # Ctrl+LeftArrow
      ZSH_FZF_HISTORY_SEARCH_FZF_ARGS="+s +m -x -e --height 40%  --height 20%  --layout reverse --info inline"
      SAVEHIST=10000  # Save most-recent 1000 lines
      HISTSIZE=10000
      setopt appendhistory
      setopt EXTENDED_HISTORY
      setopt HIST_FIND_NO_DUPS
      setopt HIST_IGNORE_ALL_DUPS

      zstyle ':completion:*' completer _complete _match _approximate
      zstyle ':completion:*:match:*' original only
      zstyle ':completion:*:approximate:*' max-errors 1 numeric
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
    '';
  };
}
