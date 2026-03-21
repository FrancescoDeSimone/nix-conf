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
      };
      opener = {
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
            name = "*.json";
            run = "rich-preview";
          }
          {
            name = "*.csv";
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
        ];
      };
    };

    initLua = ''
      require("full-border"):setup()
      require("git"):setup {
        	order = 1500,
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
      ];
    };

    plugins = {
      full-border = pkgs.yaziPlugins.full-border;
      git = pkgs.yaziPlugins.git;
      compress = pkgs.yaziPlugins.compress;
      ouch = pkgs.yaziPlugins.ouch;
      rich-preview = pkgs.yaziPlugins.rich-preview;
    };
  };
}
