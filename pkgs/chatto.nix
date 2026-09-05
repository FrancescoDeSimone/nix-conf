{
  lib,
  buildGoModule,
  nodejs_22,
  pnpm_10,
  fetchPnpmDeps,
  sqlite,
  zstd,
  inputs,
  ...
}:
buildGoModule rec {
  pname = "chatto";
  version = "0.4.8";

  src = inputs.chatto;

  modRoot = "./cli";
  vendorHash = "sha256-y+mT6RxQVxmNCCLFnkkGNu6fFN8t5imxR1LJI4DmTqM=";

  nativeBuildInputs = [nodejs_22 pnpm_10 sqlite zstd];

  pnpmDeps = fetchPnpmDeps {
    src = inputs.chatto;
    inherit pname version;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    hash = "sha256-Qm7Mw47CdJ/v4LkWJW6bsjBqjdziv30uu2z14X5PP+8=";
  };

  tags = ["bootstrap"];
  env.CGO_ENABLED = 0;
  env.GOWORK = "off";

  passthru.overrideModAttrs = _: _prev: {
    preBuild = "";
  };

  preBuild = ''
    export HOME="$TMPDIR"

    pushd "$NIX_BUILD_TOP/source"
    substituteInPlace package.json --replace-fail '"packageManager": "pnpm@10.26.0",' ""

    # Extract and configure pnpm store
    STORE_PATH=$(mktemp -d)
    tar --zstd -xf "${pnpmDeps}/pnpm-store.tar.zst" -C "$STORE_PATH"
    chmod -R +w "$STORE_PATH"

    if [ -f "$STORE_PATH/v11/index.db.sql" ]; then
      sqlite3 "$STORE_PATH/v11/index.db" < "$STORE_PATH/v11/index.db.sql"
      rm "$STORE_PATH/v11/index.db.sql"
    fi

    pnpm config set store-dir "$STORE_PATH"
    pnpm config set package-import-method clone-or-copy

    pnpm install --offline --ignore-scripts --frozen-lockfile

    pnpm --filter @chatto/api-types build
    pnpm --filter chatto-frontend build

    # Copy frontend build to Go embed directory
    rm -f cli/internal/http_server/.client/.gitkeep
    cp -r apps/frontend/build/. cli/internal/http_server/.client/

    # Setup embedded license files required by Go build
    mkdir -p cli/cmd/embedded
    cp LICENSES/AGPL-3.0-or-later.txt cli/LICENSE
    cp NOTICE cli/NOTICE
    cp LICENSES/AGPL-3.0-or-later.txt cli/cmd/embedded/LICENSE
    cp NOTICE cli/cmd/embedded/NOTICE
    popd
  '';

  doCheck = false;

  meta = with lib; {
    description = "A self-hosted chat application for teams and communities";
    homepage = "https://github.com/chattocorp/chatto";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
    mainProgram = "chatto";
  };
}
