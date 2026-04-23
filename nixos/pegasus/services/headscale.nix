{
  config,
  private,
  ...
}: {
  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = config.my.services.headscale.port;
    settings = {
      server_url = "https://headscale.${private.nginx.domain}";
      log = {
        level = "info";
        format = "text";
      };
      dns = {
        magic_dns = true;
        base_domain = "tail.${private.nginx.domain}";
        override_local_dns = true;
        nameservers.global = ["192.168.188.2"];
      };
      derp = {
        urls = ["https://controlplane.tailscale.com/derpmap/default"];
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
