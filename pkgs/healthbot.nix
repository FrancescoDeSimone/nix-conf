{
  lib,
  rustPlatform,
  inputs,
}: let
  src = inputs.healthbot;
in
  rustPlatform.buildRustPackage {
    pname = "healthbot";
    version = "0.1.0";

    inherit src;
    cargoLock.lockFile = src + "/Cargo.lock";

    meta = with lib; {
      description = "Telegram bot that turns scale and food photos into log entries via a vision model";
      homepage = "https://github.com/FrancescoDeSimone/healthbot";
      license = licenses.bsd3;
      mainProgram = "healthbot";
      platforms = platforms.linux;
    };
  }
