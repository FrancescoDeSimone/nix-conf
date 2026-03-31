{...}: {
  services.xserver.enable = true;
  catppuccin.sddm.enable = true;
  catppuccin.flavor = "mocha";
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  programs.sway.enable = true;
}
