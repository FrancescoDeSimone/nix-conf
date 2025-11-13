{
  pkgs,
  lib,
  private,
  ...
}: let
  domain = private.nginx.domain;
in {
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-opencloud"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  containers.opencloud = {
   nixpkgs = fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  sha256 = "sha256:117mzxz0a0r01nvmykdrvgfnxh1vwgg8rj2p0v3v1as1kp7ywxdd";
};

    bindMounts = {
      "/var/lib/opencloud" = {
        hostPath = "/nextcloud";
        isReadOnly = false;
      };
    };
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.103.10";
    localAddress = "192.168.103.11";
    config = {
      config,
      pkgs,
      ...
    }: {
      system.stateVersion = "25.05";
      services.opencloud = {
        enable = true;
        stateDir = "/var/lib/opencloud";
        user = "opencloud";
        group = "opencloud";
        address = "0.0.0.0";
        port = 80;
        url = "https://opencloud.${domain}";
      };
      # 6. Internal container firewall and networking
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [80 443];
      };
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
    };
  };
}
