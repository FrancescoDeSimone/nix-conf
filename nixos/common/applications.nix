{ pkgs, ... }: {
  environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    XDG_CACHE_HOME = "$HOME/.cache";
    CARGO_HOME = "$HOME/.local/share/cargo";
    GOPATH = "$HOME/.local/share/go";
    npm_config_cache = "$HOME/.cache/npm";
    NODE_REPL_HISTORY = "$HOME/.local/share/node_repl_history";
    PYTHON_HISTORY = "$HOME/.local/state/python_history";
    WGETRC = "$HOME/.config/wgetrc";
    GNUPGHOME = "$HOME/.local/share/gnupg";
    ZDOTDIR = "$HOME/.config/zsh";
    GTK2_RC_FILES = "$HOME/.config/gtk-2.0/gtkrc";
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    unstable.neovim
    jq
    yq
    file
    ripgrep
    fd
    killall
    unzip
  ];
}
