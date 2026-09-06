{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
  inputs,
}: let
  src =
    if builtins.pathExists /home/thinkcentre/ytdl_bot
    then /home/thinkcentre/ytdl_bot
    else inputs.ytdl_bot;
in
  rustPlatform.buildRustPackage {
    pname = "ytdl_bot";
    version = "0.1.0";

    inherit src;

    cargoLock.lockFile = src + "/Cargo.lock";

    nativeBuildInputs = [pkg-config];
    buildInputs = [openssl];

    meta = with lib; {
      description = "Telegram bot that extracts direct video URLs with yt-dlp";
      homepage = "https://github.com/FrancescoDeSimone/ytdl_bot";
      license = licenses.mit;
      mainProgram = "ytdl_bot";
      platforms = platforms.linux;
    };
  }
