{
  inputs,
  lib,
  stdenv,
}: let
  upkgs = inputs.nixpkgs-unstable.legacyPackages.${stdenv.hostPlatform.system};
  py = upkgs.python313Packages;
in
  py.buildPythonApplication rec {
    pname = "headroom-ai";
    version = "0.40.0";
    format = "wheel";
    src = upkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/03/1c/383f4a2d33ad18d40869037ca6221e1db24bc4da5e92befe70793220b138/headroom_ai-0.40.0-cp310-abi3-manylinux_2_28_x86_64.whl";
      hash = "sha256-SbbYoByOzrW56aZ1cg7V5Msk5GcoJkJlOqx/L9j69H8=";
    };

    propagatedBuildInputs = with py; [
      ast-grep-cli
      tiktoken
      pydantic
      litellm
      click
      rich
      opentelemetry-api
      pyyaml
      tomlkit
      truststore
      fastapi
      uvicorn
      orjson
      httpx
      h2
      openai
      mcp
      magika
      zstandard
      websockets
      onnxruntime
      transformers
      watchdog
      sqlite-vec
    ];

    makeWrapperArgs = [
      "--prefix PATH : ${lib.makeBinPath [upkgs.ast-grep]}"
    ];

    doCheck = false;
    pythonImportsCheck = ["headroom"];

    meta = {
      description = "Prompt-compression proxy for LLM agents";
      homepage = "https://github.com/headroomlabs-ai/headroom";
      license = lib.licenses.asl20;
      mainProgram = "headroom";
    };
  }
