{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    glances
    unstable.filebrowser
    powertop
    zenstates
    ryzenadj
    # archivebox # python3.12-django-3.1.14
  ];
}
