{
  config,
  private,
  ...
}: let
  opencloudPort = config.my.services.opencloud.port;
  hostAddress = "192.168.103.10";
  localAddress = "192.168.103.11";
  stateDir = "/var/lib/opencloud";
in {
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-opencloud"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 root root -"
  ];

  containers.opencloud = {
    autoStart = true;
    privateNetwork = true;
    inherit hostAddress localAddress;

    bindMounts.${stateDir} = {
      hostPath = stateDir;
      isReadOnly = false;
    };

    config = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.services.opencloud;
      usesGeneratedConfig = (cfg.settings.opencloud or {}) == {};
      adminPasswordFile = "${cfg.stateDir}/bootstrap-admin-password";
    in {
      networking.hosts = {
        "${localAddress}" = ["opencloud.${private.nginx.internalDomain}"];
      };

      services.opencloud = {
        enable = true;
        address = "0.0.0.0";
        port = opencloudPort;
        url = "https://opencloud.${private.nginx.internalDomain}";
      };

      systemd.services.opencloud-init-config = lib.mkIf (cfg.enable && usesGeneratedConfig) {
        serviceConfig.ReadWritePaths = lib.mkForce [
          "/etc/opencloud"
          cfg.stateDir
        ];

        script = lib.mkForce ''
          set -eux
          config="''${OC_CONFIG_DIR}/opencloud.yaml"

          if [ ! -e "$config" ]; then
            if [ ! -e "${adminPasswordFile}" ]; then
              umask 0077
              ${pkgs.openssl}/bin/openssl rand -hex 16 > "${adminPasswordFile}"
              chown root:root "${adminPasswordFile}"
              chmod 0400 "${adminPasswordFile}"
            fi

            echo "Provisioning initial OpenCloud config..."
            opencloud init \
              --insecure "''${OC_INSECURE:-false}" \
              --admin-password "$(< "${adminPasswordFile}")" \
              --config-path "''${OC_CONFIG_DIR}"
            chown ${cfg.user}:${cfg.group} "$config"
          fi
        '';
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [opencloudPort];
      };

      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";

      system.stateVersion = "25.11";
    };
  };
}
