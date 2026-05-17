# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{
  pkgs,
  inputs,
  ...
}: {
  # example = pkgs.callPackage ./example { };
  "13ft" = pkgs.callPackage ./13ft.nix {inherit inputs;};
  clipvault = pkgs.callPackage ./clipvault.nix {inherit inputs;};
  jaro = pkgs.callPackage ./jaro.nix {inherit inputs;};
  speedtest-tracker = pkgs.callPackage ./speedtest-tracker.nix {inherit inputs;};
  adguard-exporter = pkgs.callPackage ./adguard-exporter.nix {inherit inputs;};
  lidarr-youtube-downloader = pkgs.callPackage ./lidarr-youtube-downloader.nix {inherit inputs;};
}
