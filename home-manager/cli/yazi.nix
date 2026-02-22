{pkgs, ...}: {
  home.packages = [pkgs.rich-cli];

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    settings = {
      mgr = {
        show_hidden = true;

        sort_by = "mtime";

        sort_dir_first = true;
        linemode = "git";
        ratio = [1 4 3];
      };

      preview = {
        max_width = 1000;
        max_height = 1000;
      };

      opener = {
        extract = [
          {
            run = "ya pub extract --list %*";
            desc = "Extract here";
            for = "unix";
          }
        ];
        edit = [
          {
            run = "nvim %*";
            block = true;
            desc = "Edit";
          }
        ];
      };

      plugin = {
        prepend_previewers = [
          {
            name = "*.md";
            run = "rich-preview";
          }
          {
            name = "*.csv";
            run = "rich-preview";
          }
          {
            name = "*.json";
            run = "rich-preview";
          }
          {
            name = "*.ipynb";
            run = "rich-preview";
          }
          {
            name = "*.tar.gz";
            run = "ouch";
          }
          {
            name = "*.zip";
            run = "ouch";
          }
          {
            name = "*.7z";
            run = "ouch";
          }
        ];
      };
    };

    keymap = {
      mgr.prepend_keymap = [
        {
          on = ["C"];
          run = "plugin compress --args='zip'";
          desc = "Compress to .zip";
        }
        {
          on = ["E"];
          run = "plugin extract --args='list'";
          desc = "Extract archive";
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
      ];
    };

    plugins = {
      full-border = pkgs.yaziPlugins.full-border;
      git = pkgs.yaziPlugins.git;
      compress = pkgs.yaziPlugins.compress;
      ouch = pkgs.yaziPlugins.ouch;
      chmod = pkgs.yaziPlugins.chmod;
      mediainfo = pkgs.yaziPlugins.mediainfo;
      duckdb = pkgs.yaziPlugins.duckdb;
      rich-preview = pkgs.yaziPlugins.rich-preview;
      wl-clipboard = pkgs.yaziPlugins.wl-clipboard;
      vcs-files = pkgs.yaziPlugins.vcs-files;
    };

  };
}
