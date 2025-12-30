{outputs, ...}: {
  # You can import other home-manager modules here
  imports = [./cli/default.nix];

  home = {
    username = "thinkcentre";
    homeDirectory = "/home/thinkcentre";
    stateVersion = "25.11";
  };
}
