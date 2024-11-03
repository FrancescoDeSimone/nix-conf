{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    glances
    unstable.filebrowser
    powertop
    zenstates
    ryzenadj
    archivebox
  ];
}
