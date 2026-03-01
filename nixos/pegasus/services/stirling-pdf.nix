{ config, ... }: {
  services.stirling-pdf = {
    enable = true;
    environment = {
      INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "true";
      SERVER_PORT = toString config.my.services.stirling-pdf.port;
    };
  };
  networking.firewall.allowedTCPPorts = [ ];
}
