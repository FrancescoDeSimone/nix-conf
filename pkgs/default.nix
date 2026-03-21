# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{
  pkgs,
  inputs,
  ...
}: {
  # example = pkgs.callPackage ./example { };
  clipvault = pkgs.callPackage ./clipvault.nix {inherit inputs;};
  jaro = pkgs.callPackage ./jaro.nix {inherit inputs;};
}
