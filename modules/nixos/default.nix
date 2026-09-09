# Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  # my-module = import ./my-module.nix;
  speedtest-tracker = import ./speedtest-tracker;
  chatto = import ./chatto;
  deemix = import ./deemix;
  deemix-arr = import ./deemix-arr;
}
