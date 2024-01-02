{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    #amule-daemon
    #amule-web
    yarr
    glances
    unstable.filebrowser
    powertop
    zenstates
  ];

}
