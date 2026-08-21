{config, ...}: {
  services.stirling-pdf = {
    enable = true;
    environment = {
      # Advanced HTML ops pull in heavy/abuse-prone processing; disable for public exposure
      INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "false";
      SERVER_PORT = toString config.my.services.stirling-pdf.port;
    };
  };
  networking.firewall.allowedTCPPorts = [];
}
