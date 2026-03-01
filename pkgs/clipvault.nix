{ lib
, rustPlatform
, inputs
, pkg-config
, openssl
, sqlite
, stdenv
, darwin
,
}:
rustPlatform.buildRustPackage {
  pname = "clipvault";
  version = "0-unstable-${inputs.clipvault.shortRev}";

  src = inputs.clipvault;

  cargoLock = {
    lockFile = "${inputs.clipvault}/Cargo.lock";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs =
    [ openssl sqlite ]
    ++ lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Security ];

  doCheck = false;

  meta = with lib; {
    description = "Clipboard history manager for Wayland, inspired by cliphist";
    homepage = "https://github.com/rolv-apneseth/clipvault";
    license = licenses.agpl3Only;
    maintainers = [ ];
  };
}
