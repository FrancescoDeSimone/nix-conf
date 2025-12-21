{ outputs, ... }: {
  # You can import other home-manager modules here
  imports = [ ./cli/default.nix ];

  home = {
    username = "thinkcentre";
    homeDirectory = "/home/thinkcentre";
  };
}
