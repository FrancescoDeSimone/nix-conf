{...}: {
  imports = [../../../modules/nixos/deemix-arr];

  my.services.deemix-arr = {
    enable = true;
  };
}
