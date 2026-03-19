{
  lib,
  pkgs,
  stdenv,
  inputs,
}: let
  # 1. Load the Byparr source code
  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = inputs.byparr-src;
  };

  # 2. Translate the uv.lock into a Nix Python overlay
  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  # 3. Apply the overlay using pyproject-nix's custom builder
  pythonSet =
    (pkgs.callPackage inputs.pyproject-nix.build.packages {
      python = pkgs.python314;
    }).overrideScope (
      lib.composeManyExtensions [
        inputs.pyproject-build-systems.overlays.default
        overlay

        (final: prev: {
          camoufox = prev.camoufox.overrideAttrs (old: {
            postInstall =
              (old.postInstall or "")
              + ''
                # Find the locale.py file where the GeoIP database path is hardcoded
                LOCALE_PY=$(find $out -name locale.py -path "*/camoufox/*")

                # Rewrite the Python code to point to our persistent cache directory
                # WRAPPED IN pathlib.Path() so that .exists() doesn't throw an error!
                if [ -n "$LOCALE_PY" ]; then
                  sed -i "s|MMDB_FILE = .*|MMDB_FILE = __import__('pathlib').Path('/var/cache/byparr/GeoLite2-City.mmdb')|g" "$LOCALE_PY"
                fi
              '';
          });
        })
      ]
    );

  # 4. Generate the fully isolated, offline virtual environment!
  pythonEnv = pythonSet.mkVirtualEnv "byparr-env" workspace.deps.default;

  # 5. Provide graphical libraries for the Camoufox/Playwright browsers
  runtimeLibs = with pkgs;
    lib.makeLibraryPath [
      alsa-lib
      dbus
      fontconfig
      freetype
      glib
      gtk3
      libdrm
      libxkbcommon
      mesa
      nss
      pango
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
      stdenv.cc.cc.lib
    ];
in
  pkgs.writeShellScriptBin "byparr" ''
    STATE_DIR="''${STATE_DIRECTORY:-/tmp/byparr-state}"
    CACHE_DIR="''${CACHE_DIRECTORY:-/tmp/byparr-cache}"

    mkdir -p "$STATE_DIR" "$CACHE_DIR"

    export HOME="$STATE_DIR"
    export PLAYWRIGHT_BROWSERS_PATH="$CACHE_DIR/pw-browsers"

    # Expose standard Linux graphical libraries so the pre-compiled browsers don't crash
    export LD_LIBRARY_PATH="${runtimeLibs}:$LD_LIBRARY_PATH"

    # Copy source code so the script finds its local files (main.py, src/, etc)
    if [ ! -f "$STATE_DIR/main.py" ]; then
      cp -r ${inputs.byparr-src}/* "$STATE_DIR/"
      chmod -R +w "$STATE_DIR"
    fi

    cd "$STATE_DIR"

    # Fetch browsers via our pure Nix python environment
    ${pythonEnv}/bin/camoufox fetch
    ${pythonEnv}/bin/playwright install firefox

    # Start Byparr natively!
    exec ${pythonEnv}/bin/python main.py
  ''
