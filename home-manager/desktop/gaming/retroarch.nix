{pkgs, ...}: {
  home.packages = with pkgs; [
    rpcs3
    pcsx2
    retroarch
  ];
  xdg.configFile."retroarch/retroarch.cfg".text = ''
    video_shader_enable = "true"
    menu_driver = "xmb"
    savefile_directory = "~/.local/share/retroarch/saves"
    savestate_directory = "~/.local/share/retroarch/states"
    content_directory = "/home/fdesi/Games/Retro"
  '';

}