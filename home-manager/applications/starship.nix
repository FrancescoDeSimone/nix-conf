{ pkgs, lib, inputs, config, ... }: {
  programs.starship = {
    enable = true;
    settings = {
      directory.fish_style_pwd_dir_length =
        1; # turn on fish directory truncation
      directory.truncation_length = 2; # number of directories not to truncate
      gcloud.disabled = true; # annoying to always have on
      hostname.style = "bold green"; # don't like the default
      memory_usage.disabled =
        true; # because it includes cached memory it's reported as full a lot
      shlvl.disabled = false;
      username.style_user = "bold blue"; # don't like the default
    };
  };
}
