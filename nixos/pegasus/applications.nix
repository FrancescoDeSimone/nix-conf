{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    glances
    unstable.filebrowser
    unstable.it-tools
    powertop
    zenstates
    ryzenadj
    # archivebox # python3.12-django-3.1.14
    gcc
    pkg-config
    hadolint
    clj-kondo
    markdownlint-cli
    vale
    ruby
    tflint
    stylua
    black
    prettierd
    shellcheck
    rustfmt
    alejandra
    git
    ripgrep
    fd
    unzip
  ];
}
