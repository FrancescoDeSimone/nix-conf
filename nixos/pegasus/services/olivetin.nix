{config, pkgs, ...}: {
  services.olivetin = {
    enable = true;
    package = pkgs.olivetin-3k;
    settings = {
      ListenAddressSingleHTTPFrontend = "127.0.0.1:${toString config.my.services.olivetin.port}";
      listenAddressSingleHTTPFrontend = "127.0.0.1:${toString config.my.services.olivetin.port}";
      actions = [
        {
          title = "Reboot server";
          icon = "power";
          shell = "systemctl reboot";
        }
      ];
    };
  };
}
