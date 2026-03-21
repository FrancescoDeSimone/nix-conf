{pkgs, ...}: {
  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      reload
      youtube-chat
      sponsorblock
      quality-menu
      mpv-playlistmanager
    ];
  };
}
