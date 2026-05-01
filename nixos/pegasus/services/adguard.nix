{
  config,
  private,
  ...
}: let
  pegasusLanIp = "192.168.188.53";
  pegasusTailIp = "100.64.0.1";
  tailDomain = "tail.${private.nginx.domain}";
  pegasusTailName = "pegasus.${tailDomain}";
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
        ];
      };
      querylog.enabled = true;
      statistics.enabled = true;
    };
  };

  systemd.services.adguardhome = {
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
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
