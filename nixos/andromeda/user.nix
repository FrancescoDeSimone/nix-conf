{ pkgs
, config
, inputs
, outputs
, ...
}: {
  programs.zsh.enable = true;
  users = {
    mutableUsers = true;
    users.fdesi = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
      shell = pkgs.zsh;

      hashedPasswordFile = config.age.secrets.user-password.path;

      # Fallback/Initial password (replace string with output of `mkpasswd -m sha-512`)
      initialHashedPassword = "$6$2GE8Ii0N1poS8pST$UEyeozxUzdiM3KykSGLUuFw9O02qnNXDwjdwb9JkZKB.lFO1XVF4fhP/CMHv23P5TdYlzjT345FL/A0RBoecc1";
    };
  };

  age.identityPaths = [ "/home/fdesi/.ssh/id_rsa" ];
  age.secrets = {
    user-password.file = ../../secrets/user-password.age;

    wifi = {
      file = ../../secrets/wifi.age;
      path = "/etc/NetworkManager/system-connections/d08af413-f939-4010-8303-6d234fb224e4.nmconnection";
      mode = "600";
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    useGlobalPkgs = true;
    useUserPackages = false;
    users.fdesi = {
      imports = [
        ../../home-manager/andromeda.nix
        inputs.catppuccin.homeModules.catppuccin
      ];
    };
  };
}
