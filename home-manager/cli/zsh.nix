{
  pkgs,
  config,
  inputs,
  ...
}: {
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    sessionVariables = {
      EDITOR = "nvim";
      TERM = "xterm-256color";
      TERM_PROGRAM = "foot"; # for yazi image preview
    };
    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -lah";
      dd = "dd status=progress";
      tb = "nc termbin.com 9999";
      fd = "fd -j12";
      drag = "dragon-drop";
      drop = "dragon-drop -t";
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
          sha256 = "sha256-KmkXgK1J6iAyb1FtF/gOa0adUnh1pgFsgQOUnNngBaE=";
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
    initContent = ''
      autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      [[ -n "''${key[Up]}"   ]] && bindkey -- "''${key[Up]}"   up-line-or-beginning-search
      [[ -n "''${key[Down]}" ]] && bindkey -- "''${key[Down]}" down-line-or-beginning-search

      bindkey '^[[1;5C' forward-word # Ctrl+RightArrow
      bindkey '^[[1;5D' backward-word # Ctrl+LeftArrow
      zle -N edit-command-line
      bindkey "^X^X" edit-command-line
      ZSH_FZF_HISTORY_SEARCH_FZF_ARGS="+s +m -x -e --height 40%  --height 20%  --layout reverse --info inline"
      SAVEHIST=10000  # Save most-recent 1000 lines
      HISTSIZE=10000
      setopt appendhistory
      setopt EXTENDED_HISTORY
      setopt HIST_FIND_NO_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_IGNORE_SPACE # commands starting with a space skip history

      zstyle ':completion:*' completer _complete _match _approximate
      zstyle ':completion:*:match:*' original only
      zstyle ':completion:*:approximate:*' max-errors 1 numeric
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      FNM_PATH="$HOME/.local/share/fnm"
      if [ -d "$FNM_PATH" ]; then
        export PATH="/home/fdesi/.local/share/fnm:$PATH"
        eval "`fnm env`"
      fi
      if [ -f "$HOME/.cargo/env" ]; then
      . "$HOME/.cargo/env"
      fi
      if [ -d "$HOME/.opencode/bin" ]; then
        export PATH=/home/fdesi/.opencode/bin:$PATH
      fi
      if [ -x "$HOME/.local/bin/llama" ]; then
          export LLAMA_CACHE="$HOME/models"
          export HF_HOME="$HOME/models"
      fi

      _pb_post() {
        local loc
        loc=$(curl -sS --connect-timeout 10 --max-time 120 -D - -o /dev/null "$@" https://paste.${inputs.private.nginx.domain}/upload \
          | grep -i '^location:' | tr -d '\r' | awk '{print $2}')
        if [ -z "$loc" ]; then
          loc=$(curl -sS --connect-timeout 5 --max-time 120 -D - -o /dev/null "$@" http://192.168.104.11:8093/upload \
            | grep -i '^location:' | tr -d '\r' | awk '{print $2}')
        fi
        printf '%s' "$loc"
      }
      _pb_print() {
        case "$1" in
          http*) printf '%s\n' "$1" ;;
          /*) printf 'https://paste.${inputs.private.nginx.domain}%s\n' "$1" ;;
          *) echo "upload failed (no location header)" >&2; return 1 ;;
        esac
      }
      # Paste stdin, unlisted, 24h expiry. Usage: echo hi | pb
      pb() {
        _pb_print "$(_pb_post \
          -F "content=<-" -F "privacy=unlisted" \
          -F "expiration=24hour" -F "burn_after=0")"
      }
      # Usage: echo secret | pb-secret  |  echo secret | pb-secret "mypass"
      pb-secret() {
        local pass loc
        if [ -n "''${1:-}" ]; then
          pass="$1" # NOTE: visible in shell history, prefer the prompt
        else
          printf 'Password: ' >&2
          if ! IFS= read -rs pass </dev/tty; then
            printf '\nterminal read failed (no /dev/tty?); pass password as $1 instead\n' >&2
            return 1
          fi
          printf '\n' >&2
        fi
        [ -n "$pass" ] || { echo "empty password, aborting" >&2; return 1; }
        loc="$(_pb_post \
          -F "content=<-" -F "privacy=private" \
          -F "plain_key=$pass" \
          -F "expiration=24hour" -F "burn_after=0")"
        unset pass
        _pb_print "$loc"
      }
    '';
  };
}
