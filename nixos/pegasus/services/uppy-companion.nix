{...}: {
  imports = [../../../modules/nixos/uppy-companion];

  my.services.uppy-companion = {
    enable = true;
  };
}
