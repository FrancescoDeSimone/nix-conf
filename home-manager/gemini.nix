{
  outputs,
  pkgs,
  ...
}: {
  imports = [
    ./desktop/default.nix
    ./cli/default.nix
    ./desktop/gaming/gamescope.nix
    ./desktop/gaming/retroarch.nix
    ./desktop/wayland/default.nix
    ./cli/programming/default.nix
  ];
  home.packages = with pkgs; [
    jellyfin-tui
    unstable.freetube
    yq
    jq
    file
    ayugram-desktop
  ];
  wayland.windowManager.sway = {
    package = null;
    config.bars = [];
  };
  home = {
    username = "fdesi";
    homeDirectory = "/home/fdesi";
    stateVersion = "25.11";
  };
}
