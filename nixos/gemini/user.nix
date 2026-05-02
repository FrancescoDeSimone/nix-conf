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

  users.users.fdesi = {
    isNormalUser = true;
    extraGroups = ["networkmanager" "wheel" "video" "audio"];
    shell = pkgs.zsh;
    hashedPasswordFile = config.age.secrets.user-password.path;
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
      path = "/etc/NetworkManager/system-connections/wifi.nmconnection";
      mode = "600";
    };
  };

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    useGlobalPkgs = true;
    useUserPackages = false;
    users.fdesi = {
      imports = [
        ../../home-manager/gemini.nix
        inputs.catppuccin.homeModules.catppuccin
      ];
    };
  };
}
