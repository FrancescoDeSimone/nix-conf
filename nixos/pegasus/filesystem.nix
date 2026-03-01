{
  fileSystems."/data" = {
    device = "/dev/pool/data";
    fsType = "ext4";
    options = [ "nofail" "defaults" "noatime" "data=writeback" "nobh" "errors=continue" "commit=100" ];
  };

  fileSystems."/nextcloud" = {
    device = "/dev/disk/by-uuid/a8d7fad4-7b06-4ec0-a417-d8ffa22a4fb4";
    fsType = "ext4";
    options = [ "nofail" "defaults" "noatime" "data=writeback" "nobh" "errors=continue" "commit=100" ];
  };
}
