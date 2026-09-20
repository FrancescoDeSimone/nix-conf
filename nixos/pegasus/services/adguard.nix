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
  exporterPort = config.my.services.adguard.exporter;
  uiPort = config.my.services.adguard.port;
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
    # The module's preStart merges `settings` over
    # /var/lib/AdGuardHome/AdGuardHome.yaml on every start (nix values win), so
    # web-UI-only state (user_rules, blocked_services, ...) survives restarts
    # while everything declared here is enforced.
    mutableSettings = true;

    host = "0.0.0.0";
    port = uiPort;

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
      users = [
        {
          name = "admin";
          # This hash is public (it was committed to the public repo) — rotate the
          # password and put the new hash in nix-conf-secrets; the committed hash
          # stays only as a bootstrap fallback.
          password = private.adguard.hash or "$2b$12$H2Jjjbf9tlyfvNka2cODie/UeUF5wmKvedOUahiaQmo8hL4s/TvSe";
        }
      ];
    };
  };

  systemd.services.adguardhome = {
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
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
      # `ADGUARD_USER`/`ADGUARD_PASS` come from the agenix secret
      # `adguard-admin` (`secrets/secrets.nix`); systemd reads the 0400
      # root-only file before dropping privileges to DynamicUser, so the admin
      # password stays out of both the repo and the store.
      # `secrets/adguard-admin.age` ships with placeholder credentials; to
      # switch to the real password (and update `private.adguard.hash` to its
      # bcrypt hash):
      #   read -rsp 'AdGuard admin password: ' AGH_PASS; echo
      #   printf 'ADGUARD_USER=admin\nADGUARD_PASS=%s\n' "$AGH_PASS" |
      #     nix shell nixpkgs#age -c age -e -o secrets/adguard-admin.age \
      #       -R <(nix eval --raw -f secrets/secrets.nix '"provider.age".publicKeys' \
      #         --apply 'builtins.concatStringsSep "\n"')
      EnvironmentFile = config.age.secrets."adguard-admin".path;
      Environment = [
        "ADGUARD_HOST=http://127.0.0.1:${toString config.my.services.adguard.port}"
        "EXPORTER_PORT=${toString exporterPort}"
        "SCRAPE_INTERVAL=30"
        "LOG_LEVEL=INFO"
      ];
    };
  };

  networking.firewall = {
    interfaces.tailscale0 = {
      allowedTCPPorts = [53];
      allowedUDPPorts = [53];
    };

    # eno1 is the only NIC (uplink included), so scope AdGuard to private source
    # networks instead of exposing DNS and the admin UI on the WAN side too. The
    # private ranges also cover Incus/Docker containers and the tailnet, and
    # private source addresses cannot arrive from the internet (see rpfilter).
    extraInputRules = ''
      ip  saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } tcp dport { 53, ${toString uiPort} } accept
      ip6 saddr fc00::/7 tcp dport { 53, ${toString uiPort} } accept
      ip  saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } udp dport 53 accept
      ip6 saddr fc00::/7 udp dport 53 accept
    '';
  };
}
