{
  config,
  pkgs,
  lib,
  ...
}: let
  customParsers = pkgs.writeText "custom-parsers.conf" ''
    [PARSER]
        Name   custom_nginx
        Format regex
        Regex ^(?<remote_addr>\S+) - (?<remote_user>\S+) \[(?<time_local>[^\]]+)\] "(?<method>\S+) (?<path>\S+) (?<protocol>[^"]+)" (?<status>\d+) (?<body_bytes_sent>\d+) "(?<http_referer>[^"]*)" "(?<http_user_agent>[^"]*)" "(?<vhost>[^"]*)" (?<request_time>\S+)$
        Time_Key time_local
        Time_Format %d/%b/%Y:%H:%M:%S %z
  '';

  cfgFile = pkgs.writeText "fluent-bit.conf" ''
    [SERVICE]
      flush        1
      grace        5
      daemon       off
      log_level    info
      parsers_file ${pkgs.fluent-bit}/etc/fluent-bit/parsers.conf
      parsers_file ${customParsers}

    [INPUT]
      name           tail
      tag            nginx-access
      path           /var/log/nginx/access.log
      parser         custom_nginx
      read_from_head false
      db             /var/lib/fluent-bit/nginx-access.db
      db.sync        full

    [INPUT]
      name           tail
      tag            nginx-error
      path           /var/log/nginx/error.log
      read_from_head true
      db             /var/lib/fluent-bit/nginx-error.db
      db.sync        full

    [INPUT]
      name           tail
      tag            modsecurity
      path           /var/log/nginx/modsec_audit.log
      read_from_head true
      db             /var/lib/fluent-bit/modsec.db
      db.sync        full

    [FILTER]
      name  modify
      match nginx-access
      add   job nginx
      add   host pegasus

    [FILTER]
      name  modify
      match nginx-error
      add   job nginx-error
      add   host pegasus

    [FILTER]
      name  modify
      match modsecurity
      add   job modsecurity
      add   host pegasus

    [OUTPUT]
      name  loki
      match *
      host  127.0.0.1
      port  ${toString config.my.services.loki.port}
      labels job=fluent-bit
      label_keys $job,$host,$vhost,$method,$status,$request_time
      auto_kubernetes_labels off
      remove_keys job,host,vhost,method,status,request_time
  '';
in {
  services.fluent-bit = {
    enable = true;
    configurationFile = cfgFile;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/fluent-bit 0755 root root -"
  ];

  systemd.services.fluent-bit.serviceConfig = {
    SupplementaryGroups = lib.mkForce "nginx";
    DynamicUser = lib.mkForce false;
    User = "root";
    RestartSec = 5;
  };
}
