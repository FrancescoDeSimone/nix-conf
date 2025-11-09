{config, ...}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        box-drawings-uses-font-glyphs = true;
        font = "Fira Code:size=13";
        dpi-aware = "yes";
      };
      scrollback = {lines = 10000;};
      # url = {protocols = "http, https, ftp, ftps, file";};
    };
  };
}
