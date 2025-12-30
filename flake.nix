{
  inputs = {
    # Core
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Secrets & Hardware
    private.url = "git+ssh://git@github.com/FrancescoDeSimone/nix-conf-secrets";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    agenix.url = "github:ryantm/agenix";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # Aesthetics & Modules
    catppuccin.url = "github:catppuccin/nix/release-25.05";
    kickstart-nvim = {
      url = "github:FrancescoDeSimone/kickstart.nvim";
      flake = false;
    };
    tuxedo-rs.url = "github:AaronErhardt/tuxedo-rs";
    tuxedo-rs.inputs.nixpkgs.follows = "nixpkgs";

    # Mobile & Utils
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-android.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";

    # Rust Overlay
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    catppuccin,
    tuxedo-rs,
    rust-overlay,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    systems = ["x86_64-linux"];

    # Helper for system-specific attributes
    forEachSystem = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

    # Shared specialArgs for NixOS and Home Manager
    sharedArgs = {
      inherit inputs outputs;
      inherit (inputs) private;
    };

    allOverlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      rust-overlay.overlays.default
    ];

    # Helper for creating NixOS configurations
    mkSystem = hostName: modules:
      lib.nixosSystem {
        specialArgs = sharedArgs;
        modules =
          [
            {
              networking.hostName = hostName;
              nixpkgs.hostPlatform = "x86_64-linux";
              nixpkgs.overlays = allOverlays;
              nixpkgs.config.allowUnfree = true;
            }
          ]
          ++ modules;
      };

    # Define a helper to get configured pkgs
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = allOverlays;
      };

    # Helper for creating Home Manager configurations
    mkHome = user: host: module:
      lib.homeManagerConfiguration {
        pkgs = pkgsFor "x86_64-linux";
        extraSpecialArgs = sharedArgs;
        modules = [
          module
          catppuccin.homeModules.catppuccin
          {
            home.stateVersion = "25.11";
            systemd.user.startServices = "sd-switch";
          }
        ];
      };
  in {
    inherit lib;

    # Standard outputs
    packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});
    formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt);
    overlays = import ./overlays {inherit inputs;};
    nixosModules = import ./modules/nixos;
    homeModules = import ./modules/home-manager;

    # --- NixOS Configurations ---
    nixosConfigurations = {
      pegasus = mkSystem "pegasus" [
        ./nixos/pegasus/default.nix
        inputs.agenix.nixosModules.default
        {environment.systemPackages = [inputs.agenix.packages.x86_64-linux.default];}
      ];

      gemini = mkSystem "gemini" [
        ./nixos/gemini/default.nix
        inputs.nixos-hardware.nixosModules.tuxedo-pulse-15-gen2
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        {environment.systemPackages = [inputs.agenix.packages.x86_64-linux.default];}
      ];

      gemini-iso = mkSystem "gemini-iso" [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ./nixos/gemini/default.nix
        inputs.nixos-hardware.nixosModules.tuxedo-pulse-15-gen2
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        {
          system.extraDependencies = [
            self.nixosConfigurations.gemini.config.system.build.toplevel
          ];
          networking.hostName = lib.mkForce "gemini-iso";
          boot.supportedFilesystems = lib.mkForce ["vfat" "ext4" "ntfs" "cifs"];
          services.openssh.enable = true;
          services.openssh.settings.PermitRootLogin = "yes";
          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDM/Ia8zA09Ak7M7QCDrlBXVxuSnSDilhlp73vPjRGTq fds@fds"
          ];
        }
      ];

      andromeda = mkSystem "andromeda" [
        ./nixos/andromeda/default.nix
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        {environment.systemPackages = [inputs.agenix.packages.x86_64-linux.default];}
      ];

      andromeda-iso = mkSystem "andromeda-iso" [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ./nixos/andromeda/default.nix
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        ({pkgs, ...}: {
          system.extraDependencies = [
            self.nixosConfigurations.andromeda.config.system.build.toplevel
          ];
          environment.etc."nixos".source = ./.;
          networking.hostName = lib.mkForce "andromeda-iso";
          boot.supportedFilesystems = lib.mkForce ["vfat" "ext4" "ntfs" "cifs"];
          environment.systemPackages = [
            (pkgs.writeShellScriptBin "install-andromeda" ''
              set -e
              echo "⚠ WARNING: This will WIPE /dev/sda on Andromeda! ⚠"
              sleep 5
              echo ">>> Partitioning..."
              sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake /etc/nixos#andromeda
              echo ">>> Installing..."
              sudo nixos-install --flake /etc/nixos#andromeda --no-root-passwd
              echo ">>> Done. Reboot now."
            '')
          ];
          services.openssh.enable = true;
          services.openssh.settings.PermitRootLogin = "yes";
          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDM/Ia8zA09Ak7M7QCDrlBXVxuSnSDilhlp73vPjRGTq fds@fds"
          ];
        })
      ];
    };

    # --- Home Manager Configurations ---
    homeConfigurations = {
      "ubuntu@orangebox" = mkHome "ubuntu" "orangebox" ./home-manager/orangebox.nix;
      "thinkcentre@pegasus" = mkHome "thinkcentre" "pegasus" ./home-manager/pegasus.nix;
      "fdesi@phoenix" = mkHome "fdesi" "phoenix" ./home-manager/phoenix.nix;
      "fdesi@gemini" = mkHome "fdesi" "gemini" ./home-manager/gemini.nix;
      "fdesi@andromeda" = mkHome "fdesi" "andromeda" ./home-manager/andromeda.nix;
    };

    # --- Android ---
    nixOnDroidConfigurations.default = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs = import inputs.nixpkgs-android {system = "aarch64-linux";};
      modules = [./nixos/nix-on-droid.nix];
    };

    extraLib = {
      inherit (inputs.flake-utils.lib) system allSystems;
    };
  };
}
