{
  services.photoprism = {
    enable = true;
    address = "0.0.0.0";
    originalsPath = /data/recup_all;
    settings = {
      PHOTOPRISM_ADMIN_USER = "root";
      PHOTOPRISM_ADMIN_PASSWORD = "root";
    };
  };
}
