{
  inputs,
  outputs,
  ...
}: {
  imports = [inputs.nix-amd-ai.nixosModules.default];

  # Re-apply our llama-cpp-master overlay after the nix-amd-ai module's own
  # overlay self-injection (which `nixosModules.default` appends via
  # `nixpkgs.overlays`). Guarantees pkgs.llama-cpp-vulkan — and therefore the
  # /etc/lemonade/backends/llamacpp-vulkan symlink lemond uses — is OUR master
  # build, not the nix-amd-ai pinned one.
  nixpkgs.overlays = [outputs.overlays.llama-cpp-master];

  nix.settings = {
    substituters = ["https://nix-amd-ai.cachix.org"];
    trusted-public-keys = ["nix-amd-ai.cachix.org-1:F4OU4vw/lV2oiG6SBHZ+nqjl4EFJuqI4X9A7pvaBmhQ="];
  };

  hardware.amd-npu = {
    enable = true;
    enableNPU = true;             # XDNA2 present
    gpuTarget = "gfx1150";        # Strix Point
    enableFastFlowLM = true;
    enableLemonade = true;
    lemonade.user = "fdesi";
    enableVulkan = true;          # RADV on 880M
    enableROCm = false;           # repo bench: Vulkan faster on gfx1150
    enableImageGen = false;       # LLM-only, drops sd-cpp closures (~150MB CPU / 1.5GB ROCm)
    enableVllm = false;           # default; 7.6GB closure, no Cachix substitute
    lemonade.desktopApp.enable = false;   # skip Rust/webkit2gtk build; web UI served by lemond
    lemonade.flashAttn = "on";
    lemonade.settings.max_loaded_models = 2;  # NPU model + one GPU model stay resident
  };
}
