{
  pkgs,
  config,
  inputs,
  outputs,
  ...
}: {
  programs.zsh.enable = true;

  system.activationScripts.import-gpg-key = ''
    GPG_KEY="${config.age.secrets.gpg-key.path}"
    if [ -f "$GPG_KEY" ]; then
      mkdir -p /home/fdesi/.local/share/gnupg
      chown -R fdesi:users /home/fdesi/.local/share/gnupg
      ${pkgs.gnupg}/bin/gpg --homedir /home/fdesi/.local/share/gnupg --batch --import "$GPG_KEY" 2>/dev/null || true
      chown -R fdesi:users /home/fdesi/.local/share/gnupg/private-keys-v1.d/ 2>/dev/null || true
    fi
  '';

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-rofi;
  };

  users = {
    mutableUsers = true;
    users.fdesi = {
      isNormalUser = true;
      extraGroups = ["networkmanager" "wheel" "video" "audio"];
      shell = pkgs.zsh;

      hashedPasswordFile = config.age.secrets.user-password.path;

      # Fallback/Initial password (replace string with output of `mkpasswd -m sha-512`)
      initialHashedPassword = "$6$2GE8Ii0N1poS8pST$UEyeozxUzdiM3KykSGLUuFw9O02qnNXDwjdwb9JkZKB.lFO1XVF4fhP/CMHv23P5TdYlzjT345FL/A0RBoecc1";
    };
  };

  age.identityPaths = ["/home/fdesi/.ssh/id_rsa"];
  age.secrets = {
    user-password.file = ../../secrets/user-password.age;
    gpg-key = {
      file = ../../secrets/gpg-key.age;
      owner = "fdesi";
      mode = "600";
    };
    wifi = {
      file = ../../secrets/wifi.age;
      path = "/etc/NetworkManager/system-connections/d08af413-f939-4010-8303-6d234fb224e4.nmconnection";
      mode = "600";
    };
  };

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs; host = "andromeda";};
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
