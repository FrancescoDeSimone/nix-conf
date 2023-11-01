{ pkgs, ...}:
{
	environment.systemPackages = with pkgs; [
   	yarr
	glances
        unstable.filebrowser
   ];

}
