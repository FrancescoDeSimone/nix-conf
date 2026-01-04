# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  # additions = final: _prev: import ../pkgs {pkgs = final;};
  additions = final: _prev:
    import ../pkgs {
      pkgs = final;
      inherit inputs;
    };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    # neovim = inputs.nixvim.packages.${prev.system}.default;
    rofi-calc = prev.rofi-calc.override {rofi-unwrapped = prev.rofi-unwrapped;};
    rofi-top = prev.rofi-top.override {rofi-unwrapped = prev.rofi-unwrapped;};
    rofi-vpn = prev.rofi-vpn.override {rofi-unwrapped = prev.rofi-unwrapped;};
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
      };
    };
  };
}
