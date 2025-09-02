{config, ...}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        box-drawings-uses-font-glyphs = true;
        font = "Fira Code:size=12";
        dpi-aware = "yes";
      };
      scrollback = {lines = 10000;};
      url = {protocols = "http, https, ftp, ftps, file";};
    };
  };
  # catppuccin.foot.enable = config.catppuccin.enable;
}
