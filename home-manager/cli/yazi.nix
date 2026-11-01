{pkgs, ...}: {
  home.packages = [pkgs.rich-cli pkgs.ouch];

  catppuccin.yazi.enable = true;

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "mtime";
        sort_dir_first = true;
        linemode = "size";
        ratio = [1 4 3];
      };
      preview = {
        max_width = 1000;
        max_height = 1000;
        image_filter = "lanczos3";
      };
      opener = {
        edit = [
          {
            block = true;
            desc = "Edit";
            run = "nvim %*";
          }
        ];
        # default play opener is `xdg-open` (and a `mediainfo` entry that is not installed)
        play = [
          {
            block = true;
            desc = "Play with mpv";
            run = "mpv %*";
          }
        ];
      };
      plugin = {
        prepend_previewers = [
          {
            url = "*.md";
            run = "rich-preview";
          }
          {
            url = "*.json";
            run = "rich-preview";
          }
          {
            url = "*.csv";
            run = "rich-preview";
          }
          # ouch handles zip/gzip/bzip2/7z/rar/xz/zstd/jar by mime
          {
            mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}";
            run = "ouch";
          }
        ];
        # git.yazi needs explicit fetchers, otherwise it silently renders nothing
        prepend_fetchers = [
          {
            url = "*";
            run = "git";
            group = "git";
          }
          {
            url = "*/";
            run = "git";
            group = "git";
          }
        ];
      };
    };

    initLua = ''
      require("full-border"):setup()
      require("git"):setup {
        order = 1500,
      }

      local catppuccin_theme = require("yatline-catppuccin"):setup("mocha")
      require("yatline"):setup {
        theme = catppuccin_theme,
      }

      th.dupes = th.dupes or {}
      th.dupes.mark_style = ui.Style():fg("blue")
      th.dupes.mark_sign = "X"

      require("dupes"):setup {
        profiles = {
          interactive = { args = { "-r" } },
          apply = { args = { "-r", "-N", "-d" }, save_op = true },
        },
      }
    '';

    keymap = {
      mgr.prepend_keymap = [
        {
          on = ["C"];
          run = "plugin compress --args='zip'";
          desc = "Compress to .zip";
        }
        {
          on = ["<C-n>"];
          run = "arrow 1";
          desc = "Move down";
        }
        {
          on = ["<C-p>"];
          run = "arrow -1";
          desc = "Move up";
        }
        {
          on = ["<Backspace>"];
          run = "leave";
          desc = "Go back";
        }
        {
          on = ["l"];
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
        {
          on = ["T"];
          run = "plugin toggle-pane min-preview";
          desc = "Show or hide the preview pane";
        }
        {
          on = ["M"];
          run = "plugin mount";
          desc = "Mount / unmount / eject partitions";
        }
        {
          on = ["<C-d>"];
          run = "plugin diff";
          desc = "Diff the selected with the hovered file";
        }
        {
          on = ["<A-j>" "i"];
          run = "plugin dupes interactive";
          desc = "Find duplicates";
        }
        {
          on = ["<A-j>" "d"];
          run = "plugin dupes dry";
          desc = "Find duplicates (dry run)";
        }
        {
          on = ["<A-j>" "a"];
          run = "plugin dupes apply";
          desc = "Find duplicates and delete them";
        }
      ];
    };

    plugins = {
      full-border = pkgs.yaziPlugins.full-border;
      git = pkgs.yaziPlugins.git;
      compress = pkgs.yaziPlugins.compress;
      ouch = pkgs.yaziPlugins.ouch;
      rich-preview = pkgs.yaziPlugins.rich-preview;
      smart-enter = pkgs.yaziPlugins.smart-enter;
      toggle-pane = pkgs.yaziPlugins.toggle-pane;
      mount = pkgs.yaziPlugins.mount;
      diff = pkgs.yaziPlugins.diff;
      dupes = pkgs.yaziPlugins.dupes;
      yatline = pkgs.yaziPlugins.yatline;
      yatline-catppuccin = pkgs.yaziPlugins.yatline-catppuccin;
    };
  };
}
