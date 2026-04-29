{ config
, lib
, private
, ...
}:
let
  pegasusLanIp = "192.168.188.53";
  pegasusTailIp = "100.64.0.1";
  headscaleHost = "headscale.${private.nginx.domain}";
  headscaleAuthKeyFile = ../../../secrets/headscale-authkey.age;
  hasHeadscaleAuthKey = builtins.pathExists headscaleAuthKeyFile;
  advertisedRoutes = "${pegasusLanIp}/32";
  tailscaleFlags = [
    "--accept-dns=false"
    "--accept-routes=false"
    "--hostname=pegasus"
    "--advertise-routes=${advertisedRoutes}"
  ];
in
{
  networking.hosts = lib.mkIf hasHeadscaleAuthKey {
    "127.0.0.1" = [ headscaleHost ];
  };

  age.secrets = lib.optionalAttrs hasHeadscaleAuthKey {
    "headscale-authkey" = {
      file = headscaleAuthKeyFile;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  services.tailscale = lib.mkIf hasHeadscaleAuthKey {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    authKeyFile = config.age.secrets."headscale-authkey".path;
    extraUpFlags = [
      "--reset"
      "--login-server=https://${headscaleHost}"
    ] ++ tailscaleFlags;
  };

  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = config.my.services.headscale.port;
    settings = {
      server_url = "https://${headscaleHost}";
      log = {
        level = "info";
        format = "text";
      };
      dns = {
        magic_dns = true;
        base_domain = "tail.${private.nginx.domain}";
        override_local_dns = hasHeadscaleAuthKey;
        nameservers.global = lib.optional hasHeadscaleAuthKey pegasusTailIp;
      };
      derp = {
        urls = [ "https://controlplane.tailscale.com/derpmap/default" ];
        auto_update_enabled = true;
      };
      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "";
        allocation = "sequential";
      };
      database = {
        type = "sqlite";
        sqlite = {
          path = "/var/lib/headscale/db.sqlite";
          write_ahead_log = true;
        };
      };
      policy = {
        mode = "file";
        path = "/etc/headscale/acl.hujson";
      };
    };
  };

  environment.etc."headscale/acl.hujson".text = ''
    {
      "groups": {},
      "tagOwners": {},
      "acls": [
        {
          "action": "accept",
          "src": ["*"],
          "dst": ["*:*"],
        }
      ],
    }
  '';
}
