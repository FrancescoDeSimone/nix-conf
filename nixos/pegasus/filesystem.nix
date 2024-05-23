{ config, pkgs, ... }:

{
  fileSystems."/data" = {
    device = "/dev/pool/data";
    fsType = "ext4";
    options = ["nofail" "defaults" "noatime" "data=writeback" "barrier=0" "nobh" "errors=continue" "commit=100" ];
  };

  fileSystems."/nextcloud" = {
    device = "/dev/sda2";
    fsType = "ext4";
    options = ["nofail" "defaults" "noatime" "data=writeback" "barrier=0" "nobh" "errors=continue" "commit=100" ];
  };
}

