# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{
  pkgs,
  inputs,
  ...
}: let
  basePackages = {
    "13ft" = pkgs.callPackage ./13ft.nix {inherit inputs;};
    clipvault = pkgs.callPackage ./clipvault.nix {inherit inputs;};
    jaro = pkgs.callPackage ./jaro.nix {inherit inputs;};
    adguard-exporter = pkgs.callPackage ./adguard-exporter.nix {inherit inputs;};
    lidarr-youtube-downloader = pkgs.callPackage ./lidarr-youtube-downloader.nix {inherit inputs;};
    chatto = pkgs.callPackage ./chatto.nix {inherit inputs;};
    headroom-ai = pkgs.callPackage ./headroom-ai.nix {inherit inputs;};
    pass-securid = pkgs.callPackage ./pass-securid.nix {inherit inputs;};
    deemix = pkgs.callPackage ./deemix.nix {inherit inputs;};
    opengym-api = pkgs.callPackage ./opengym-api.nix {inherit inputs;};
    opengym-frontend = pkgs.callPackage ./opengym-frontend.nix {inherit inputs;};
    deemix-arr = pkgs.callPackage ./deemix-arr.nix {};
    deemix-cli = inputs.deemix.packages.${pkgs.stdenv.hostPlatform.system}.cli;
    typetype-downloader = pkgs.callPackage ./typetype-downloader.nix {go_1_27 = pkgs.go_1_27; inherit inputs;};
    typetype-server = pkgs.callPackage ./typetype-server.nix {};
    typetype-token = pkgs.callPackage ./typetype-token.nix {};
    typetype-web = pkgs.callPackage ./typetype-web.nix {};
  };
in
  basePackages
  // {
    ytdl-bot = pkgs.callPackage ./ytdl_bot.nix {inherit inputs;};
  }
