{pkgs, ...}: {
  imports = [./droid/sshd.nix];
  environment.packages = with pkgs; [
    vim
    nvim
    procps
    openssh
    killall
    diffutils
    findutils
    utillinux
    tzdata
    #hostname
    #man
    gnugrep
    gnupg
    gnused
    gnutar
    bzip2
    gzip
    xz
    zip
    unzip
  ];

  environment.etcBackupExtension = ".bak";
  system.stateVersion = "24.05";
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  time.timeZone = "Europe/Rome";
}
