{config, syncthingCert, syncthingKey, ...}: {
  services.syncthing = {
    enable = true;
    tray.enable = true;
    cert = syncthingCert;
    key = syncthingKey;
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        pegasus = {id = "<PEBGUS-DEVICE-ID>";};
        gemini = {id = "<GEMINI-DEVICE-ID>";};
        andromeda = {id = "<ANDROMEDA-DEVICE-ID>";};
        phoenix = {id = "<PHOENIX-DEVICE-ID>";};
      };
      folders.freetube = {
        path = "~/.config/FreeTube";
        devices = ["pegasus" "gemini" "andromeda" "phoenix"];
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
