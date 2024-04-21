{ pkgs, ... }: {
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    listenPort = 8888;
    package = pkgs.unstable.homepage-dashboard;
    # settings = { };
    # bookmarks = [ ];
    # services = [ ];
    # widgets = [ ];
    # docker = { };
  };

}
