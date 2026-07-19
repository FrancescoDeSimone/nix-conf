{config, ...}: {
  services.syncthing = {
    enable = true;
    user = "thinkcentre";
    dataDir = "/data/syncthing";
    openDefaultPorts = true;
    cert = config.age.secrets."syncthing-pegasus-cert".path;
    key = config.age.secrets."syncthing-pegasus-key".path;
    settings = {
      devices = {
        pegasus = {id = "<PEBGUS-DEVICE-ID>";};
        gemini = {id = "<GEMINI-DEVICE-ID>";};
        andromeda = {id = "<ANDROMEDA-DEVICE-ID>";};
        phoenix = {id = "<PHOENIX-DEVICE-ID>";};
      };
      folders.freetube = {
        path = "/data/syncthing/freetube-sync";
        devices = ["gemini" "andromeda"];
        ignorePatterns = [
          "Cache_Data"
          "SingletonCookie"
          "SingletonLock"
          "SingletonSocket"
          "lockfile"
        ];
      };
    };
  };
}
