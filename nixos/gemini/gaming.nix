{pkgs, ...}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = ["amdgpu"];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    lutris # Unified game manager
    heroic # Epic Games & GOG launcher
    bottles # Wine prefix manager (for .exe games)

    mangohud # FPS and system monitor overlay
    protonup-qt # GUI to install GE-Proton (GloriousEggroll) for better compatibility
    gamescope # Micro-compositor
  ];

  environment.sessionVariables = {
    AMD_VULKAN_ICD = "RADV";
  };
}
