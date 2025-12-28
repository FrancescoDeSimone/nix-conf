{pkgs, ...}: let
  nativeArgs = "-W 1920 -H 1080 -f";
  gs-720p = pkgs.writeShellScriptBin "gs-720p" ''
    exec ${pkgs.gamescope}/bin/gamescope \
      -w 1280 -h 720 \
      ${nativeArgs} \
      -F fsr \
      --sharpness 2 \
      -- "$@"
  '';
  gs-retro = pkgs.writeShellScriptBin "gs-retro" ''
    exec ${pkgs.gamescope}/bin/gamescope \
      -w 960 -h 540 \
      ${nativeArgs} \
      -S integer \
      -- "$@"
  '';
in {
  home.packages = with pkgs; [
    gamescope
    gs-720p
    gs-retro
  ];
}
