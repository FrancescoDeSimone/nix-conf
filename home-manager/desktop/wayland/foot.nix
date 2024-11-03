{
  programs.foot = {
    catppuccin.enable = true;
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
}
