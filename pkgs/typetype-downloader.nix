# TypeType downloader: Go backend that fetches media (YouTube segments,
# BiliBili/NicoNico sources, muxing via libavformat), stores artifacts in
# Garage (S3) and reports job results back to the server. Unlike the
# server/token/web bundles this component builds cleanly from source
# (buildGoModule, vendored deps, CGO like upstream).
{
  lib,
  buildGoModule,
  go_1_27,
  ffmpeg,
  pkg-config,
  makeWrapper,
  inputs,
}:
let
  # go.mod demands Go >= 1.27 while the branch's buildGoModule ships with the
  # default (older) toolchain, so the composition is overridden before use.
  buildGo127Module = buildGoModule.override {go = go_1_27;};
in
  buildGo127Module rec {
  pname = "typetype-downloader";
  # The VERSION file is bumped per release; strip a stray trailing newline.
  version = let
    raw = builtins.readFile (inputs.typetype-downloader + "/VERSION");
  in
    lib.removeSuffix "\n" (lib.removeSuffix "\r" raw);

  src = inputs.typetype-downloader;

  # go.mod requires go 1.27: the branch default go is older, hence the
  # explicit input override in pkgs/default.nix.
  go = go_1_27;

  subPackages = ["cmd/server"];

  vendorHash = "sha256-G1ebWAUgz0YhFg7qWHBuMMSD7DdwME8JVL8oNEAWNCY=";

  env.CGO_ENABLED = "1";
  nativeBuildInputs = [pkg-config makeWrapper];
  buildInputs = [ffmpeg];

  ldflags = [
    "-s"
    "-w"
    "-X" "typetype-downloader-go/internal/buildinfo.Version=${version}"
    "-X" "typetype-downloader-go/internal/buildinfo.Revision=${inputs.typetype-downloader.rev}"
    "-X" "typetype-downloader-go/internal/buildinfo.BuildTime=1970-01-01T00:00:00Z"
  ];

  postInstall = ''
    mv $out/bin/server $out/bin/typetype-downloader
    # MUXER=avformat needs libav* shared objects and/or an ffmpeg in PATH
    # at runtime (upstream installs ffmpeg in the runner image too).
    wrapProgram $out/bin/typetype-downloader \
      --prefix PATH : ${lib.makeBinPath [ffmpeg]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ffmpeg]}
  '';

  meta = {
    description = "TypeType media downloader service (source build)";
    license = lib.licenses.gpl3;
  };
}
