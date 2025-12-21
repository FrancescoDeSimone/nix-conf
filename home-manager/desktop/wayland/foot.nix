# {config, ...}: {
#   programs.foot = {
#     enable = true;
#     settings = {
#       main = {
#         box-drawings-uses-font-glyphs = true;
#         font = "Fira Code:size=13";
#         dpi-aware = "yes";
#       };
#       scrollback = {lines = 10000;};
#     };
#   };
# }
{
  config,
  pkgs,
  ...
}: {
  # 1. Disable the Catppuccin module for Foot (stops the deprecation warning)
  # TODO: add it back when catppuccin get fixes
  catppuccin.foot.enable = false;

  programs.foot = {
    enable = true;
    settings = {
      main = {
        box-drawings-uses-font-glyphs = true;
        font = "Fira Code:size=13";
        dpi-aware = "yes";
      };
      scrollback = {lines = 10000;};

      colors = {
        alpha = "1.0";
        background = "1e1e2e";
        foreground = "cdd6f4";
        cursor = "1e1e2e cdd6f4";

        # Normal colors
        regular0 = "45475a"; # Surface 1
        regular1 = "f38ba8"; # Red
        regular2 = "a6e3a1"; # Green
        regular3 = "f9e2af"; # Yellow
        regular4 = "89b4fa"; # Blue
        regular5 = "f5c2e7"; # Pink
        regular6 = "94e2d5"; # Teal
        regular7 = "bac2de"; # Subtext 1

        # Bright colors
        bright0 = "585b70"; # Surface 2
        bright1 = "f38ba8"; # Red
        bright2 = "a6e3a1"; # Green
        bright3 = "f9e2af"; # Yellow
        bright4 = "89b4fa"; # Blue
        bright5 = "f5c2e7"; # Pink
        bright6 = "94e2d5"; # Teal
        bright7 = "a6adc8"; # Subtext 0
        # Misc
        selection-foreground = "cdd6f4";
        selection-background = "414559";
        urls = "f5e0dc";
      };
    };
  };
}
