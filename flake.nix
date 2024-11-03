{
  description = "Nix config";

  inputs = {
    private.url = "git+ssh://git@github.com/FrancescoDeSimone/nix-conf-secrets";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim.url = "github:francescodesimone/nixvim";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    catppuccin.url = "github:catppuccin/nix";
    flake-utils.url = "github:numtide/flake-utils";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs-unstable";
    agenix.url = "github:ryantm/agenix";
    # nixified-ai = "github:nixified-ai/flake";
    # arkenfox = {
    #   url = "github:dwarfmaster/arkenfox-nixos";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    flake-utils,
    private,
    catppuccin,
    disko,
    home-manager,
    agenix,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    systems = ["x86_64-linux"];
    forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs systems (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
  in {
    inherit lib;
    packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});
    formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt);
    overlays = import ./overlays {inherit inputs;};
    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;
    homeConfigurations = {
      pegasus = home-manager.lib.homeManagerConfiguration {
        pkgs =
          nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./home-manager/pegasus.nix
          catppuccin.homeManagerModules.catppuccin
        ];
      };
      "fdesi@phoenix" = home-manager.lib.homeManagerConfiguration {
        pkgs =
          nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./home-manager/phoenix.nix
          catppuccin.homeManagerModules.catppuccin
        ];
      };
    };
    extraLib = {
      system = flake-utils.lib.system;
      allSystems = flake-utils.lib.allSystems;
    };
    nixosConfigurations = {
      pegasus = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
          inherit private;
        };
        modules = [
          ./nixos/pegasus.nix
          disko.nixosModules.disko
          agenix.nixosModules.default
          {
            environment.systemPackages = [agenix.packages.x86_64-linux.default];
          }
        ];
      };
    };
  };
}
