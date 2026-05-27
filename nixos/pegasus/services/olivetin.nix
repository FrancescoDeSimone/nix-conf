{
  config,
  ...
}: {
  nixpkgs.config.permittedInsecurePackages = [
    "olivetin-2025.11.25"
  ];
  services.olivetin = {
    enable = true;
    settings = {
      ListenAddressSingleHTTPFrontend = "127.0.0.1:${toString config.my.services.olivetin.port}";
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
