{ pkgs
, inputs
, ...
}: {
  #disabledModules = ["services/web-apps/stirling-pdf.nix"];
  #imports = [
  #  "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/stirling-pdf.nix"
  #];
  services.stirling-pdf = {
    enable = true;
    #package = pkgs.unstable.stirling-pdf;
    environment = {
      INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "true";
      SERVER_PORT = 8080;
    };
  };
}
