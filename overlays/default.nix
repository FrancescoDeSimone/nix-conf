# This file defines overlays
{inputs, ...}: let
  # llama.cpp master tip pinned for the llama-cpp-master overlay.
  # Resolved on 2026-08-14 with: nix flake prefetch --json github:ggml-org/llama.cpp
  # Must stay >= b10430-equivalent (qwen35/Qwen3.8 arch) and carry both the
  # Muse Glimmer and Nemotron 3.5 (Mamba-2 hybrid) arches. Verified against this
  # exact rev: src/models/{qwen35,muse-glimmer,nemotron}.cpp present, qwen35
  # handles 64 layers (LLM_TYPE_27B). Re-resolve before rebuilding master.
  masterRev = "7e4c0a96880dae4fc4268ad441f8a6446bd5460a";
  masterHash = "sha256-Sz0kW1q91YzdrKbZUqMbFJ0DLZrzARSGheUrtCKcoQo=";
in {
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
  modifications = _final: prev: {
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

  # llama.cpp built from master. Only `llama-cpp-vulkan` is overridden: the
  # nix-amd-ai lemond module reads ${pkgs.llama-cpp-vulkan}/bin/llama-server
  # from the host's final pkgs, so this flows into the
  # /etc/lemonade/backends/llamacpp-vulkan symlink automatically.
  llama-cpp-master = final: prev: {
    llama-cpp-vulkan =
      (final.llama-cpp.override {vulkanSupport = true;})
      .overrideAttrs (old: {
        version = "master-${builtins.substring 0 8 masterRev}";
        src = final.fetchFromGitHub {
          owner = "ggml-org";
          repo = "llama.cpp";
          rev = masterRev;
          hash = masterHash;
        };
        # Master's tools/ui/package-lock.json differs from the release's, so
        # the inherited npmDepsHash is stale. Value taken from the failed
        # fixed-output build. Re-derive (nix-build error prints it) if the pin
        # is bumped.
        npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
        # nixpkgs injects -DLLAMA_BUILD_NUMBER=<version>; build-info.cpp needs
        # an integer, but our version is master-<rev>. Append the actual commit
        # count (git rev-list --count HEAD at the pin = 10434) — CMake last-wins.
        cmakeFlags = (old.cmakeFlags or []) ++ ["-DLLAMA_BUILD_NUMBER=10434"];
      });
  };
}
