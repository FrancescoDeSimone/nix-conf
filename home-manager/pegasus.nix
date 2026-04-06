{...}: {
  # You can import other home-manager modules here
  imports = [./cli/default.nix];

  home = {
    username = "thinkcentre";
    homeDirectory = "/home/thinkcentre";
    stateVersion = "25.11";
  };

  # Headless server: no Wayland/X11 clipboard provider available.
  # Use OSC 52 so copy/paste works over SSH via terminal escape sequences.
  xdg.configFile."nvim/after/plugin/clipboard.lua".text = ''
    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
        ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
      },
      paste = {
        ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
        ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
      },
    }
  '';
}
