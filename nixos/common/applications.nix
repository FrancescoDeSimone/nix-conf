{pkgs, ...}: {
  environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/etc";
    XDG_DATA_HOME = "$HOME/var/lib";
    XDG_CACHE_HOME = "$HOME/var/cache";
  };

  environment.systemPackages = with pkgs; [
    unstable.neovim
    git
    wget
    curl
    jq
    yq
    file
    ripgrep
    fd
    killall
    unzip
  ];
}
