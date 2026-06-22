{...}: {
  imports = [./modules.nix ./style.nix];
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = ["graphical-session.target"];
    };
  };
}
