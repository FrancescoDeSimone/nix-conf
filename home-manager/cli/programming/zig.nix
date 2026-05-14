{pkgs, ...}: {
  home.packages = [
    pkgs.zigpkgs.default
  ];
}
