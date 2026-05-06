{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  tabbyPort = 5050;
  tabbyModelName = "qwen2.5-coder-3b";
  tabbyPromptTemplate = "qwen2.5";
  tabbyModelDir = "${config.home.homeDirectory}/.local/share/tabbyapi/models";
  tabbyDataDir = "${config.home.homeDirectory}/.local/share/tabbyapi";
  tabbySrcDir = "${tabbyDataDir}/src";
  tabbyVenvDir = "${tabbyDataDir}/venv";
  tabbyMain = "${tabbySrcDir}/main.py";
  tabbyPython = "${tabbyVenvDir}/bin/python";
in {
  imports = [./desktop/default.nix ./cli/default.nix ./desktop/wayland/default.nix];

  home.packages = with pkgs; [jellyfin-tui yq jq ayugram-desktop opencode uv git];
  modules.editors.neovim.extras = false;

  systemd.user.services.tabbyapi = {
    Unit = {
      Description = "TabbyAPI local inference server";
      After = ["default.target"];
    };
    Install = {
      WantedBy = ["default.target"];
    };
    Service = {
      WorkingDirectory = "%h/.config/tabbyapi";
      TimeoutStartSec = "30min";
      ExecStartPre = pkgs.writeShellScript "tabbyapi-prepare" ''
        set -eu
        mkdir -p "${tabbyModelDir}" "${tabbyDataDir}"

        if [ ! -d "${tabbySrcDir}/.git" ]; then
          rm -rf "${tabbySrcDir}"
          ${pkgs.git}/bin/git clone https://github.com/theroyallab/tabbyAPI "${tabbySrcDir}"
        fi

        if [ ! -x "${tabbyPython}" ]; then
          ${pkgs.uv}/bin/uv venv "${tabbyVenvDir}" --python 3.13
        fi

        if [ ! -f "${tabbyVenvDir}/.tabby-installed" ]; then
          ${pkgs.uv}/bin/uv pip install --python "${tabbyPython}" -U "${tabbySrcDir}[cu12]"
          touch "${tabbyVenvDir}/.tabby-installed"
        fi

        if ${pkgs.uv}/bin/uv pip show --python "${tabbyPython}" xformers >/dev/null 2>&1; then
          ${pkgs.uv}/bin/uv pip uninstall --python "${tabbyPython}" xformers
        fi
      '';
      ExecStart = "${tabbyPython} ${tabbyMain}";
      Environment = [
        "PYTHONUNBUFFERED=1"
        "HF_HOME=%h/.cache/huggingface"
      ];
      Restart = "on-failure";
      RestartSec = "2";
    };
  };

  home.file.".local/bin/tabbyapi-update" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -eu
      ${pkgs.git}/bin/git -C "${tabbySrcDir}" pull --ff-only
      rm -f "${tabbyVenvDir}/.tabby-installed"
      ${pkgs.uv}/bin/uv pip install --python "${tabbyPython}" -U "${tabbySrcDir}[cu12]"
      if ${pkgs.uv}/bin/uv pip show --python "${tabbyPython}" xformers >/dev/null 2>&1; then
        ${pkgs.uv}/bin/uv pip uninstall --python "${tabbyPython}" xformers
      fi
      touch "${tabbyVenvDir}/.tabby-installed"
      systemctl --user restart tabbyapi
    '';
  };

  xdg.configFile."tabbyapi/config.yml".text = ''
    network:
      host: 127.0.0.1
      port: ${toString tabbyPort}
      disable_auth: true
      api_servers: ["OAI"]

    model:
      model_dir: ${tabbyModelDir}
      inline_model_loading: true
      use_dummy_models: false
      use_as_default: ["max_seq_len", "chunk_size", "prompt_template"]
      gpu_split_auto: true
      chunk_size: 1024
      max_seq_len: 8192
      prompt_template: "${tabbyPromptTemplate}"

    sampling:
      override_preset: safe_defaults

    memory:
      cuda_malloc_async: true

    developer:
      unsafe_launch: false
  '';

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    model = "tabby/${tabbyModelName}";
    small_model = "tabby/${tabbyModelName}";
    plugin = ["opencode-gemini-auth@latest"];
    instructions = [
      "~/.config/opencode/instructions/source-first.md"
      "~/.config/opencode/instructions/products.md"
    ];
    permission = {
      external_directory = {
        "~/git/**" = "allow";
      };
      skill = {
        "*" = "allow";
      };
    };
    agent = {
      build = {
        top_p = 0.8;
      };
      plan = {
        top_p = 0.8;
      };
    };
    provider = {
      google = {
        options = {
          projectId = "fdesi-demo";
          timeout = 600000;
          chunkTimeout = 60000;
        };
      };
      ollama = {
        name = "Ollama (local)";
        npm = "@ai-sdk/openai-compatible";
        options = {
          baseURL = "http://localhost:11434/v1";
          timeout = 600000;
          chunkTimeout = 60000;
        };
        models = {
          "gemma4:26b" = {
            name = "Gemma 4 26B";
            limit = {
              context = 4096;
              output = 4096;
            };
          };
          "gemma4:26b-a4b-it-q8_0" = {
            name = "Gemma 4 26B (Q8)";
            limit = {
              context = 4096;
              output = 4096;
            };
          };
          "gemma4:e4b" = {
            name = "Gemma 4 e4B";
            limit = {
              context = 4096;
              output = 2048;
            };
          };
          "qwen3.5:27b" = {
            name = "Qwen 3.5 27B";
            limit = {
              context = 4096;
              output = 4096;
            };
          };
        };
      };
      tabby = {
        name = "TabbyAPI (local)";
        npm = "@ai-sdk/openai-compatible";
        options = {
          baseURL = "http://127.0.0.1:${toString tabbyPort}/v1";
          timeout = 600000;
          chunkTimeout = 60000;
        };
        models = {
          "${tabbyModelName}" = {
            name = "Qwen 2.5 Coder 3B Local";
            tool_call = true;
            limit = {
              context = 8192;
              output = 4096;
            };
          };
        };
      };
    };
  };

  xdg.configFile."tabbyapi/templates/${tabbyPromptTemplate}.jinja".text = ''
    {# Metadata #}
    {% set stop_strings = ["<|im_start|>", "<|im_end|>"] %}
    {% set tool_start = "<tool_call>" %}

    {# Template #}
    {%- if tools %}
        {{- '<|im_start|>system\n' }}
        {%- if messages[0]['role'] == 'system' %}
            {{- messages[0]['content'] }}
        {%- else %}
            {{- 'You are Qwen, created by Alibaba Cloud. You are a helpful assistant.' }}
        {%- endif %}
        {{- "\n\n# Tools\n\nYou may call one or more functions to assist with the user query.\n\nYou are provided with function signatures within <tools></tools> XML tags:\n<tools>" }}
        {%- for tool in tools %}
            {{- "\n" }}
            {{- tool | tojson }}
        {%- endfor %}
        {{- "\n</tools>\n\nFor each function call, return a json object with function name and arguments within <tool_call></tool_call> XML tags:\n<tool_call>\n{\"name\": <function-name>, \"arguments\": <args-json-object>}\n</tool_call><|im_end|>\n" }}
    {%- else %}
        {%- if messages[0]['role'] == 'system' %}
            {{- '<|im_start|>system\n' + messages[0]['content'] + '<|im_end|>\n' }}
        {%- else %}
            {{- '<|im_start|>system\nYou are Qwen, created by Alibaba Cloud. You are a helpful assistant.<|im_end|>\n' }}
        {%- endif %}
    {%- endif %}
    {%- for message in messages %}
        {%- if (message.role == "user") or (message.role == "system" and not loop.first) or (message.role == "assistant" and not message.tool_calls) %}
            {{- '<|im_start|>' + message.role + '\n' + message.content + '<|im_end|>' + '\n' }}
        {%- elif message.role == "assistant" %}
            {{- '<|im_start|>' + message.role }}
            {%- if message.content %}
                {{- '\n' + message.content }}
            {%- endif %}
            {%- for tool_call in message.tool_calls %}
                {%- if tool_call.function is defined %}
                    {%- set tool_call = tool_call.function %}
                {%- endif %}
                {{- '\n<tool_call>\n{\"name\": \"' }}
                {{- tool_call.name }}
                {{- '\", \"arguments\": ' }}
                {{- tool_call.arguments | tojson }}
                {{- '}\n</tool_call>' }}
            {%- endfor %}
            {{- '<|im_end|>\n' }}
        {%- elif message.role == "tool" %}
            {%- if (loop.index0 == 0) or (messages[loop.index0 - 1].role != "tool") %}
                {{- '<|im_start|>user' }}
            {%- endif %}
            {{- '\n<tool_response>\n' }}
            {{- message.content }}
            {{- '\n</tool_response>' }}
            {%- if loop.last or (messages[loop.index0 + 1].role != "tool") %}
                {{- '<|im_end|>\n' }}
            {%- endif %}
        {%- endif %}
    {%- endfor %}
    {%- if add_generation_prompt %}
        {{- '<|im_start|>assistant\n' }}
    {%- endif %}
  '';

  xdg.dataFile."tabbyapi/models/README.txt".text = ''
    Put EXL2 or EXL3 model directories here for TabbyAPI.

    The default OpenCode model ID is `${tabbyModelName}`.
    For TabbyAPI inline loading to work, the model directory name should match
    the requested model ID, or you should update both of these files together:

    - ~/.config/tabbyapi/config.yml
    - ~/.config/opencode/opencode.json

    Recommended starting point for phoenix:
    - a Qwen2.5-Coder-3B-Instruct EXL2 quant
    - stored as ~/.local/share/tabbyapi/models/${tabbyModelName}

    The bundled TabbyAPI prompt template is `${tabbyPromptTemplate}`, which
    matches the Qwen 2.5 chat and tool-call format.
  '';

  xdg.dataFile."wayland-sessions/sway-nvidia.desktop".text = ''
    [Desktop Entry]
    Name=Sway (Nvidia)
    Comment=An i3-compatible Wayland compositor
    Exec=env WLR_DRM_DEVICES=/dev/dri/card1:/dev/dri/card2 WLR_NO_HARDWARE_CURSORS=1 /usr/bin/sway --unsupported-gpu
    Type=Application
  '';
  modules.desktop.sway.wallpaper = "/usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png";
  wayland.windowManager = {
    sway = {
      package = null;
      checkConfig = false;
      enable = true;
      config = {
        workspaceOutputAssign = [
          {
            workspace = "1";
            output = "DP-2";
          }
          {
            workspace = "2";
            output = "DP-2";
          }
          {
            workspace = "3";
            output = "DP-2";
          }
          {
            workspace = "4";
            output = "DP-2";
          }
          {
            workspace = "5";
            output = "DP-2";
          }
          {
            workspace = "6";
            output = "HDMI-A-1";
          }
          {
            workspace = "7";
            output = "HDMI-A-1";
          }
          {
            workspace = "8";
            output = "HDMI-A-1";
          }
          {
            workspace = "9";
            output = "HDMI-A-1";
          }
          {
            workspace = "10";
            output = "eDP-1";
          }
        ];
      };
    };
  };
  programs = {
    swaylock.package = null;
    mpv = {
      enable = true;
      package = pkgs.mpv;
      config = {
        vo = "wlshm";
        hwdec = "auto";
        msg-level = "ffmpeg=error";
        scale = "spline36";
        cscale = "spline36";
      };
    };
  };
  home = {
    username = "fdesi";
    homeDirectory = "/home/fdesi";
  };
}
