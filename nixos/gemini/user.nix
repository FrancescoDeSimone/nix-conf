{
  pkgs,
  config,
  inputs,
  outputs,
  ...
}: {
  programs.zsh.enable = true;

  users.users.fdesi = {
    isNormalUser = true;
    extraGroups = ["networkmanager" "wheel" "video" "audio"];
    shell = pkgs.zsh;
    hashedPasswordFile = config.age.secrets.user-password.path;
  };

  age.identityPaths = ["/home/fdesi/.ssh/id_rsa"];
  age.secrets = {
    user-password.file = ../../secrets/user-password.age;
    wifi = {
      file = ../../secrets/wifi.age;
      path = "/etc/NetworkManager/system-connections/wifi.nmconnection";
      mode = "600";
    };
  };

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    useGlobalPkgs = true;
    useUserPackages = true;
    users.fdesi = {
      imports = [
        ../../home-manager/gemini.nix
        inputs.catppuccin.homeModules.catppuccin
      ];
    };
  };
}
