{
  config,
  private,
  pkgs,
  ...
}: let
  pegasusLanIp = "192.168.188.53";
  pegasusTailIp = "100.64.0.1";
  tailDomain = "tail.${private.nginx.domain}";
  pegasusTailName = "pegasus.${tailDomain}";
  exporterPort = 9618;
  exporterUserCleanup = pkgs.writeShellScript "adguard-exporter-user-cleanup" ''
    set -eu
    config_file="/var/lib/AdGuardHome/AdGuardHome.yaml"
    if [ ! -f "$config_file" ]; then
      exit 0
    fi

    temp_file=$(${pkgs.coreutils}/bin/mktemp)

    ${pkgs.yq-go}/bin/yq 'del(.users[] | select(.name == "exporter"))' "$config_file" > "$temp_file"
    ${pkgs.coreutils}/bin/cat "$temp_file" > "$config_file"

    users_len="$(${pkgs.yq-go}/bin/yq '.users | length // 0' "$config_file")"
    if [ "$users_len" -eq 0 ]; then
      ${pkgs.yq-go}/bin/yq 'del(.users)' "$config_file" > "$temp_file"
      ${pkgs.coreutils}/bin/cat "$temp_file" > "$config_file"
    fi

    rm -f "$temp_file"
  '';
  upstreamResolvers = [
    "1.1.1.1"
    "1.0.0.1"
    "8.8.8.8"
    "8.8.4.4"
  ];
  blocklistFilters = [
    {
      name = "AdGuard DNS filter";
      url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
      enabled = true;
    }
    {
      name = "AdAway official hosts";
      url = "https://adaway.org/hosts.txt";
      enabled = true;
    }
    {
      name = "Pete Lowe blocklist hosts";
      url = "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext";
      enabled = true;
    }
    {
      name = "StevenBlack Unified hosts";
      url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
      enabled = true;
    }
    {
      name = "gambling";
      url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling/hosts";
      enabled = true;
    }
    {
      name = "porn";
      url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts";
      enabled = true;
    }
    {
      name = "spotify";
      url = "https://raw.githubusercontent.com/Isaaker/Spotify-AdsList/main/Lists/standard_list.txt";
      enabled = true;
    }
  ];
in {
  services.adguardhome = {
    enable = true;
    openFirewall = false;
    mutableSettings = true;

    host = "0.0.0.0";
    port = config.my.services.adguard.port;

    settings = {
      filters = blocklistFilters;
      dns = {
        ratelimit = 0;
        bind_hosts = [
          "127.0.0.1"
          pegasusLanIp
          pegasusTailIp
        ];
        port = 53;
        bootstrap_dns = upstreamResolvers;
        upstream_dns =
          [
            "[/${tailDomain}/]100.100.100.100"
          ]
          ++ upstreamResolvers;
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;

        # Resolve all VPN-only service aliases through the pegasus node.
        rewrites = [
          {
            domain = "adguard.pegasus.lan";
            answer = pegasusLanIp;
            enabled = true;
          }
          {
            domain = "pegasus.lan";
            answer = pegasusTailName;
            enabled = true;
          }
          {
            domain = "*.pegasus.lan";
            answer = pegasusTailName;
            enabled = true;
          }
          {
            domain = private.nginx.internalDomain;
            answer = pegasusTailName;
            enabled = true;
          }
          {
            domain = "*.${private.nginx.internalDomain}";
            answer = pegasusTailName;
            enabled = true;
          }
        ];
      };
      querylog.enabled = true;
      statistics.enabled = true;
    };
  };

  systemd.services.adguardhome = {
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
    # serviceConfig.PermissionsStartOnly = true;
    preStart = ''
      ${exporterUserCleanup}
    '';
  };

  systemd.services.adguard-exporter = {
    description = "AdGuard Home Prometheus Exporter";
    after = ["adguardhome.service" "network.target"];
    requires = ["adguardhome.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.adguard-exporter}/bin/adguardexporter";
      Restart = "on-failure";
      DynamicUser = true;
      WorkingDirectory = "/tmp";
      StateDirectory = "adguard-exporter";
      RuntimeDirectory = "adguard-exporter";
      Environment = [
        "ADGUARD_HOST=http://127.0.0.1:${toString config.my.services.adguard.port}"
        "ADGUARD_USER="
        "ADGUARD_PASS="
        "EXPORTER_PORT=${toString exporterPort}"
        "SCRAPE_INTERVAL=30"
        "LOG_LEVEL=INFO"
      ];
    };
  };

  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };

  networking.firewall.interfaces.eno1 = {
    allowedTCPPorts = [53 config.my.services.adguard.port];
    allowedUDPPorts = [53];
  };
}
