{
  description = "Nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim.url = "github:francescodesimone/nixvim";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    catppuccin.url = "github:catppuccin/nix";
    flake-utils.url = "github:numtide/flake-utils";
    # nixified-ai = "github:nixified-ai/flake";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs-unstable";
    arkenfox = {
      url = "github:dwarfmaster/arkenfox-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    flake-utils,
    arkenfox,
    catppuccin,
    disko,
    home-manager,
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
    arkenfox = arkenfox.hmModules.default;
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
      arkenfox = arkenfox.lib.arkenfox;
    };
    nixosConfigurations = {
      pegasus = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./nixos/pegasus.nix disko.nixosModules.disko];
      };
    };
  };
}
