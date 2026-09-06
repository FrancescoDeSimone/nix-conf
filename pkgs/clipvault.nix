{
  lib,
  rustPlatform,
  inputs,
  pkg-config,
  openssl,
  sqlite,
  stdenv,
  darwin,
}:
rustPlatform.buildRustPackage {
  pname = "clipvault";
  version = "0-unstable-${inputs.clipvault.shortRev}";

  src = inputs.clipvault;

  cargoLock = {
    lockFile = "${inputs.clipvault}/Cargo.lock";
    outputHashes = {
      "wayrs-client-1.3.1" = "sha256-KAgnYuBXSJev3esCaK+FtOjdi23j/OwaY0ymo2egvO0=";
      "wayrs-core-1.0.5" = "sha256-KAgnYuBXSJev3esCaK+FtOjdi23j/OwaY0ymo2egvO0=";
      "wayrs-proto-parser-3.0.1" = "sha256-KAgnYuBXSJev3esCaK+FtOjdi23j/OwaY0ymo2egvO0=";
      "wayrs-protocols-0.14.11+1.45" = "sha256-KAgnYuBXSJev3esCaK+FtOjdi23j/OwaY0ymo2egvO0=";
      "wayrs-scanner-0.15.4" = "sha256-KAgnYuBXSJev3esCaK+FtOjdi23j/OwaY0ymo2egvO0=";
    };
  };

  nativeBuildInputs = [pkg-config];

  buildInputs =
    [openssl sqlite]
    ++ lib.optionals stdenv.isDarwin [darwin.apple_sdk.frameworks.Security];

  doCheck = false;

  meta = with lib; {
    description = "Clipboard history manager for Wayland, inspired by cliphist";
    homepage = "https://github.com/rolv-apneseth/clipvault";
    license = licenses.agpl3Only;
    maintainers = [];
  };
}
