{private, ...}: let
  qbuser = private.qb.user;
  qbpasswd = private.qb.passwd;
in {
  services.qbittorrent = {
    enable = true;
    user = "thinkcentre";
    group = "thinkcentre";
    profileDir = "/data/qbittorrent";
    openFirewall = true;
    serverConfig = {
      LegalNotice.Accepted = true;
      Preferences = {
        WebUI = {
          Username = qbuser;
          Password_PBKDF2 = qbpasswd; # "SfTOev9GN/PIq2m2U1u23w==:Y0csFQSOkYVi89pluuZW8plV3iou4hh7wdhfoW18ZkSeNrla2qbrNBuSuRndV0vhJzdNEVgCPedfYOqLfu9QBA==";
        };
        General.Locale = "en";
      };
    };
  };
  users.users.thinkcentre = {
    isNormalUser = true;
    group = "thinkcentre";
  };
  users.groups.thinkcentre = {};
}
