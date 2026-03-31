{outputs, ...}: {
  imports = [./cli/default.nix];

  home = {
    username = "ubuntu";
    homeDirectory = "/home/ubuntu";
  };
}
