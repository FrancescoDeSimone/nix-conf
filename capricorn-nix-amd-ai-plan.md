# capricorn-nix-amd-ai — new SLIMBOOK Excalibur 16 host + AMD AI inference stack

> **Status: approved plan, execution deferred** (laptop not yet in hand, 2026-08-12). Execute when the machine arrives. All facts verified 2026-08-12.

## Context

Add a NixOS laptop host `capricorn` (user's stated candidate name, Saint-Seiya Capricorn) for a SLIMBOOK Excalibur 16: AMD Ryzen AI 9 365 (10C/20T, Radeon 880M RDNA3.5 / gfx1150, XDNA2 NPU 50 TOPS), 64GB DDR5 (2x32 SO-DIMM, ~89.6–120 GB/s), 4TB NVMe, WiFi 6, ships without OS. End state: the host booted from the repo's flake, with the `noamsto/nix-amd-ai` flake wired for NPU (FastFlowLM) + GPU (llama.cpp Vulkan via RADV) inference through the Lemonade server, and four usable models:

| Model | Backend | Est. t/s (anchored) |
|---|---|---|
| Nemotron 3.5 Lightning 30B-A3B `UD-Q4_K_XL` (~20GB) | 880M Vulkan | 15–30 (3B active; repo bench: 26B-4B-active = 17.5 t/s) |
| Muse Glimmer 30B `UD-Q4_K_XL` ~17GB + mmproj | 880M Vulkan | 4–7 (dense 30B, bandwidth-bound) |
| Qwen3.6-27B `Q4_K_M` ~16GB | 880M Vulkan | 4–6 (dense) |
| Qwen3-8B (Q4NX, FLM) | XDNA2 NPU | 10–12 (AMD FLM docs, Krackan Point ≈ 365) |

Qwen3.8-27B (release 2026-08-14) gets the same one-line slot once GGUFs land. Feasibility (researched online, all facts current as of 2026-08-12): all three GGUF sets exist on HF (`unsloth/…-GGUF` repos, exact filenames verified below); llama.cpp supports Muse Glimmer (mtmd, day-0 merge) and Nemotron 3.5 (Mamba-2 hybrid, NVIDIA-collab merge) only in master-recent builds — NOT in nixos-26.05 or the nix-amd-ai pinned nixpkgs (~llama.cpp b10273). Hence the master llama.cpp override in step 3. ROCm is skipped: nix-amd-ai's own gfx1150 benches show Vulkan faster (17.5 vs 13.9 t/s on the same model) and gfx1150 is natively covered by RADV.

## Approach

### 1. Nix-amd-ai flake input
`flake.nix` inputs: add after the `tuxedo-rs` block:
```nix
nix-amd-ai.url = "github:noamsto/nix-amd-ai";
```
Do NOT add `nix-amd-ai.inputs.nixpkgs.follows = "nixpkgs"` (README warning: re-hashes every backend, loses Cachix).

### 2. Overlay wiring in `flake.nix`
In `outputs` → `let`, extend `allOverlays` (current list: additions, modifications, unstable-packages, rust-overlay, zig-overlay, headplane) by appending, in this order:
```nix
inputs.nix-amd-ai.overlays.default
outputs.overlays.llama-cpp-master
```
Later overlay wins for `llama-cpp-vulkan`. Effect on other hosts: inert — only adds lazily-evaluated attrs; no closure change unless a host already uses llama-cpp-vulkan (none do).

### 3. Master llama.cpp overlay — `overlays/default.nix`
Add overlay `llama-cpp-master` to the exported set (alongside additions/modifications/unstable-packages):
```nix
llama-cpp-master = final: prev: {
  llama-cpp-vulkan = (final.llama-cpp.override { vulkanSupport = true; }).overrideAttrs (old: {
    version = "master-${builtins.substring 0 8 masterRev}";
    src = final.fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      rev = masterRev;
      hash = masterHash;
    };
  });
};
```
with `masterRev`/`masterHash` bound at the top of `overlays/default.nix`:
```
nix flake prefetch --json github:ggml-org/llama.cpp
```
→ copy `locked.rev` → `masterRev`, `locked.narHash` → `masterHash`. Must be a tip with BOTH Muse Glimmer (mtmd) and Nemotron 3.5 (Mamba-2/LatentMoE) support; resolve on implementation day; validate with Verification V3 (if one arch fails, re-prefetch a few days later — day-0 merges landed 2026-08-10/11).
The nix-amd-ai module references `${pkgs.llama-cpp-vulkan}/bin/llama-server` from the host's final pkgs, so this override automatically flows into the `/etc/lemonade/backends/llamacpp-vulkan` symlink and lemond's seed — no module change needed.
If `final.llama-cpp.override` errors on `vulkanSupport`, this attr already has it applied; use `final.llama-cpp-vulkan` as the base of `overrideAttrs` instead (still our overlay, wins the attr).

### 4. Host directory `nixos/capricorn/` — five files, all clones with deltas

**`disks.nix`** — verbatim copy of `nixos/gemini/disks.nix` (ESP 512M vfat /boot; LUKS `crypted` + LVM vg `pool`; `root` ext4 100%FREE /; `swap` 16G), device `/dev/nvme0n1` (4TB).

**`hardware.nix`** — copy of `nixos/gemini/hardware.nix` with these excisions only: remove the `boot.extraModulePackages` line (`tuxedo-drivers yt6801` — TUXEDO-only) and the `hardware.tuxedo-rs` block. Keep everything else: `linuxPackages_latest`, `kernelModules = ["amd-pstate"]`, initrd.luks modules, kernelParams (`acpi.ec_no_wakeup=1`, `amdgpu.dcdebugmask=0x10`, zswap ×4, `amd_pstate=active`, `amdgpu.ppfeaturemask=0xffffffff`), systemd-boot, initrd systemd + `nvme xhci_pci usb_storage sd_mod tpm_tis`, sysctl block, bluetooth powerOnBoot, firmware linux-firmware, blueman, power-profiles-daemon, tpm2 + pkcs11 + tctiEnvironment, lact/lm_sensors, thermald. ADD:
```nix
hardware.graphics.enable = true;   # mesa/RADV — required for Vulkan inference; gemini gets this from its nixos-hardware module, we don't use one
```

**`desktop.nix`** — verbatim copy of `nixos/gemini/desktop.nix` (xserver.enable, catppuccin.sddm.enable + mocha, sddm.wayland.enable, programs.sway.enable).

**`user.nix`** — copy of `nixos/gemini/user.nix` with two deltas: (a) in the home-manager block change `host = "gemini"` → `host = "capricorn"` and the import `../../home-manager/gemini.nix` → `../../home-manager/capricorn.nix`; (b) add `"render"` to `users.users.fdesi.extraGroups` (nix-amd-ai README: user must be in `video` + `render`; keep existing `networkmanager wheel video audio`). Keep the gpg import activation, zsh, age.identityPaths `~/.ssh/id_rsa`, and the three age secrets verbatim.

**`default.nix`** — copy of `nixos/gemini/default.nix` imports list, with: `./gaming.nix` → `./ai.nix`, and REMOVE the `inputs.nixos-hardware.nixosModules.tuxedo-pulse-15-gen2` import (no Excalibur/Slimbook profile in nixos-hardware — only `slimbook/hero`; skipped). Keep: `../common`, `./disks.nix`, `./hardware.nix`, `./user.nix`, `./desktop.nix`, `./ai.nix`, `inputs.disko.nixosModules.disko`, `inputs.home-manager.nixosModules.home-manager`, `inputs.agenix.nixosModules.default`, `inputs.catppuccin.nixosModules.catppuccin`, the openssh block, `services.tailscale.enable = true`.

### 5. `nixos/capricorn/ai.nix` (new)
```nix
{ inputs, ... }: {
  imports = [ inputs.nix-amd-ai.nixosModules.default ];

  nix.settings = {
    substituters = [ "https://nix-amd-ai.cachix.org" ];
    trusted-public-keys = [ "nix-amd-ai.cachix.org-1:F4OU4vw/lV2oiG6SBHZ+nqjl4EFJuqI4X9A7pvaBmhQ=" ];
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
```
The module handles the rest (amdxdna module/udev/PAM memlock, XRT env, lemond unit, `/etc/lemonade/backends` symlinks, defaults seed + reconcile, nix-ld).

### 6. Flake registration — `flake.nix`
- `nixosConfigurations`: add
```nix
capricorn = mkSystem "capricorn" [
  ./nixos/capricorn/default.nix
  inputs.disko.nixosModules.disko
  inputs.agenix.nixosModules.default
  { environment.systemPackages = [ inputs.agenix.packages.x86_64-linux.default ]; }
];
```
- `capricorn-iso` = clone of `andromeda-iso` (installation-cd-minimal + `./nixos/capricorn/default.nix` + disko + agenix + `system.extraDependencies` of capricorn toplevel + `install-capricorn` helper script running disko on `/dev/nvme0n1` then `nixos-install --flake /etc/nixos#capricorn`, root ssh key `fds@fds`). Needed: the machine ships without an OS.
- `homeConfigurations`: add `"fdesi@capricorn" = mkHome "fdesi" "capricorn" ./home-manager/capricorn.nix;`.

### 7. `home-manager/capricorn.nix` — clone + lemonade seeds
Copy `home-manager/gemini.nix` verbatim (its imports: `./desktop/default.nix`, `./cli/default.nix`, gaming, `./desktop/wayland/default.nix`, `./cli/programming/default.nix` — keep any host-specific bits as-is). Append two declarative seeds (lemonade cache lives at `~/.cache/lemonade`, owned by fdesi; lemond runs as fdesi):

```nix
home.file.".cache/lemonade/user_models.json" = {
  text = builtins.toJSON {
    "Nemotron-3.5-Lightning" = {
      source = "huggingface";
      checkpoint = "unsloth/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-GGUF:NVIDIA-Nemotron-3.5-Lightning-30B-A3B-UD-Q4_K_XL.gguf";
      recipe = "llamacpp";
      size = 20;
      labels = [ "tool-calling" "reasoning" ];
    };
    "Muse-Glimmer-30B" = {
      source = "huggingface";
      checkpoint = "unsloth/Muse-Glimmer-30B-GGUF:Muse-Glimmer-30B-UD-Q4_K_XL.gguf";
      mmproj = "mmproj-Muse-Glimmer-30B-BF16.gguf";
      recipe = "llamacpp";
      size = 18;
      labels = [ "vision" "tool-calling" ];
    };
    "Qwen3.6-27B" = {
      source = "huggingface";
      checkpoint = "unsloth/Qwen3.6-27B-GGUF:Qwen3.6-27B-Q4_K_M.gguf";
      recipe = "llamacpp";
      size = 16;
      labels = [ "reasoning" ];
    };
  };
};
home.file.".cache/lemonade/recipe_options.json" = {
  text = builtins.toJSON {
    "user.Nemotron-3.5-Lightning" = { ctx_size = 32768; llamacpp_backend = "vulkan"; };
    "user.Muse-Glimmer-30B" = { ctx_size = 32768; llamacpp_backend = "vulkan"; };
    "user.Qwen3.6-27B" = { ctx_size = 16384; llamacpp_backend = "vulkan"; };
  };
};
```
Schema (from lemonade docs `guide/configuration/custom-models.md`): `user_models.json` keys are bare names, `mmproj` is a top-level filename in the same HF repo; `recipe_options.json` keys are `user.<name>`, `llamacpp_backend: "vulkan"` forces the Vulkan backend. Drift: lemond rewrites user_models.json on pull/delete; the next `nixos-rebuild switch` restores the declared seed — accepted.

### 8. NPU models — no config needed
FastFlowLM (from the module) provides `flm`; models come from AMD's catalog: `flm run qwen3:8b` (Q4NX, ~5.5GB). Documented on fastflowlm.com (model card: `qwen3:8b`, 32k default ctx). No lemonade-FLM registration in this plan (its exact model wiring is unconfirmed); the standalone `flm` CLI is the verified NPU path. `qwen3vl-it:4b` is available the same way for NPU vision.

### 9. Secrets
`secrets/secrets.nix` holds two ed25519 recipient pubkeys. Add capricorn's own pubkey (generated during install) to the recipients list, then from a machine holding an existing decryption key run the repo's agenix rekey so `user-password.age`, `gpg-key.age`, `wifi.age` carry the new recipient. If instead reusing the existing `~/.ssh/id_rsa` (copy it onto capricorn), skip the secrets edit entirely. Do this BEFORE `nixos-install` runs activation (agenix decrypts at activation; the installer environment must have the identity).

### 10. Default model alias (one-time, post-first-boot)
```bash
lemonade alias add default user.Nemotron-3.5-Lightning
lemonade alias add fast qwen3:8b
```
Nemotron is default: it is the only candidate that is fast on the 880M (3B active, ~15–30 t/s) while covering agentic/coding; NPU `qwen3:8b` (FLM) is aliased `fast` for low-power/quick work; Glimmer and Qwen3.6-27B remain selectable.

## Critical files & anchors
- `flake.nix` — inputs (~line 24 tuxedo-rs block), `allOverlays` (~line 61), `nixosConfigurations` (~line 180, gemini entry), `homeConfigurations` (~line 260).
- `overlays/default.nix` — add `llama-cpp-master` export.
- `nixos/gemini/{default,hardware,user,desktop,disks}.nix` — clone templates for `nixos/capricorn/`.
- `nixos/capricorn/ai.nix` — nix-amd-ai module wiring (step 5).
- `home-manager/gemini.nix` — clone template; append HM seeds (step 7).
- `secrets/secrets.nix` — recipient list (step 9).

## Verification
On the laptop (rooted in `/home/fdesi/git/personal/nix-conf`), after `nixos-rebuild switch --flake .#capricorn` (which also activates home-manager):
1. **Service**: `systemctl status lemond` active; `readlink /etc/lemonade/backends/llamacpp-vulkan` ends in the *master* store path; `jq .llamacpp /home/fdesi/.cache/lemonade/config.json` shows `vulkan_bin=/etc/lemonade/backends/llamacpp-vulkan` and `args="--flash-attn on"`.
2. **Master llama.cpp / arch support (the load-bearing risk)**: as fdesi, `llama-server --version` (commit ≈ master) and `llama-cli -m <downloaded Glimmer gguf> --mmproj <mmproj file> --no-warmup -p "hi" -n 4` prints a loaded vocab/arch — no "unknown architecture" error. Repeat for the Nemotron GGUF. If either fails with an arch error → re-prefetch a newer llama.cpp master (day-0 support merged 2026-08-10/11), update `masterRev`/`masterHash`, rebuild, re-check.
3. **Models**: `lemonade list` shows the three `user.*` entries (from HM seed); then download + load each: `lemonade pull user.Nemotron-3.5-Lightning && lemonade run user.Nemotron-3.5-Lightning -p "Solve 27*43" -n 64` etc. (first run downloads several GB; wired network needed).
4. **NPU**: `flm list` shows qwen3:8b; `flm run qwen3:8b` streams a reply (proves amdxdna/XRT/FLM). `sudo dmesg | grep -i amdxdna` clean.
5. **Performance (answers the "are you sure" question)**: `llama-bench -m <each gguf> -ngl 999 --no-mmap -n 32` (llama-bench ships with the master package). Acceptance ranges: Nemotron ≥ 12 t/s; Glimmer ≥ 3 t/s; Qwen3.6-27B ≥ 3 t/s; NPU qwen3:8b ≈ 8–13 t/s (AMD FLM doc range: 11.9 @1k → 7.2 @32k). If llama-bench is not in the package, time a 100-token completion via `time curl localhost:13305/v1/chat/completions -d '{"model":"default",...}'` instead.
6. **Vision**: `curl localhost:13305/v1/chat/completions` with `model=user.Muse-Glimmer-30B` and an image content URL (or base64 data URL) → model describes the image (exercises mmproj).
7. **Qwen3.8-27B (from 2026-08-14)**: `lemonade pull user.Qwen3-8-27B --checkpoint main unsloth/Qwen3.8-27B-GGUF:<exact-file-from-repo-listing>` (discover the variant through the pull prompt; the repo name is the unsloth convention), add the entry to the HM seed in `home-manager/capricorn.nix`, rebuild, `lemonade run user.Qwen3-8-27B`. Contingency: if llama.cpp master doesn't recognize the arch yet, bump `masterRev` (step 2's flow) and re-verify — no config change needed.

## Assumptions & contingencies
- **Hostname** `capricorn` is the user's stated candidate ("maybe capricorn"); if they settle on another name, rename in exactly these spots: `nixosConfigurations.capricorn` + `capricorn-iso` keys, `homeConfigurations."fdesi@capricorn"`, dir `nixos/capricorn/`, file `home-manager/capricorn.nix`, and the `mkSystem "capricorn"` argument (networking.hostName).
- **RAM bandwidth** assumed 89.6 GB/s (DDR5-5600 2ch; the 2x32 SO-DIMM config). If LPDDR5X-7500 (120 GB/s), everything is faster; no config depends on it.
- **WiFi chip** is undisclosed on the product page → only NetworkManager + `linux-firmware`. If no wlan appears after install: `lspci` the chip and add `hardware.enableAllFirmware = true` (pre-decided fallback).
- **Identity/secrets**: at least one age decryptable identity must be present at install time (dedicated key added to `secrets/secrets.nix` + rekey, or the existing `~/.ssh/id_rsa` copied onto the laptop). If skipped, activation fails on the age files — do it before `nixos-install`.
- **llama.cpp master rev** resolved on implementation day (step 3); the arch-support check (V2/V3) is the gate; fallback is a later prefetch + rebuild.
- **Qwen3.8-27B artifacts** unknown until release; the entry is added after release (step 7 of Verification), not planned blind.