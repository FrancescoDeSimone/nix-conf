{
  pkgs,
  config,
  inputs,
  outputs,
  ...
}: {
  programs.zsh.enable = true;

  users.users.thinkcentre = {
    isNormalUser = true;
    description = "thinkcentre";
    extraGroups = ["networkmanager" "wheel" "incus" "docker"];
    shell = pkgs.zsh;
  };

  users.groups.thinkcentre = {};

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    useGlobalPkgs = true;
    useUserPackages = false;
    users.thinkcentre = {
      imports = [
        ../../home-manager/pegasus.nix
        inputs.catppuccin.homeModules.catppuccin
      ];
    };
  };
}
