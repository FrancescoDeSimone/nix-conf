{pkgs, ...}: {
  home.packages = with pkgs; [
    rpcs3
    pcsx2
    (retroarch.withCores (cores:
      with cores; [
        beetle-psx-hw
        snes9x
        genesis-plus-gx
        mgba
      ]))
  ];
  xdg.configFile."retroarch/retroarch.cfg".text = ''
    # Enable FSR upscaling if you are using Gamescope
    video_shader_enable = "true"
    # Menu Driver (XMB is the classic PS3-style interface)
    menu_driver = "xmb"
    # Save states and saves in a central location
    savefile_directory = "~/.local/share/retroarch/saves"
    savestate_directory = "~/.local/share/retroarch/states"
  '';
}
