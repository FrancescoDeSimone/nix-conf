{
  config,
  lib,
  pkgs,
  ...
}: let
  headscaleTailnetMetricsDir = "/var/lib/prometheus-node-exporter-textfile";
  headscaleTailnetMetricsScript = pkgs.writeShellScript "headscale-tailnet-metrics" ''
        set -euo pipefail

        metrics_tmp="$(mktemp "${headscaleTailnetMetricsDir}/headscale-tailnet.prom.XXXXXX")"
        json_tmp="$(mktemp)"
        trap 'rm -f "$metrics_tmp" "$json_tmp"' EXIT

        cat > "$metrics_tmp" <<'EOF'
    # HELP headscale_tailnet_scrape_success Whether the Headscale tailnet scrape succeeded.
    # TYPE headscale_tailnet_scrape_success gauge
    EOF

        if ${lib.getExe config.services.headscale.package} nodes list --output json > "$json_tmp"; then
          printf 'headscale_tailnet_scrape_success 1\n' >> "$metrics_tmp"
          ${pkgs.jq}/bin/jq -r '
            def esc:
              tostring
              | gsub("\\\\"; "\\\\\\\\")
              | gsub("\n"; "\\n")
              | gsub("\""; "\\\"");
            def metric_line:
              "headscale_tailnet_node_online{node_id=\"\(.id)\",hostname=\"\((.given_name // \"\") | esc)\",fqdn=\"\((.name // \"\") | esc)\",user=\"\((.user.name // \"\") | esc)\",tailnet_ip=\"\((.ip_addresses[0] // \"\") | esc)\"} \(if .online then 1 else 0 end)";
            [
              "# HELP headscale_tailnet_node_online Whether the tailnet node is currently online.",
              "# TYPE headscale_tailnet_node_online gauge"
            ]
            + map(metric_line)
            + [
              "# HELP headscale_tailnet_nodes_total Total Headscale nodes by online state.",
              "# TYPE headscale_tailnet_nodes_total gauge",
              "headscale_tailnet_nodes_total{state=\"online\"} \(map(select(.online == true)) | length)",
              "headscale_tailnet_nodes_total{state=\"offline\"} \(map(select(.online != true)) | length)"
            ]
            | .[]
          ' "$json_tmp" >> "$metrics_tmp"
        else
          printf 'headscale_tailnet_scrape_success 0\n' >> "$metrics_tmp"
        fi

        chmod 0644 "$metrics_tmp"
        mv "$metrics_tmp" "${headscaleTailnetMetricsDir}/headscale-tailnet.prom"
  '';
in {
  systemd.services.headscale-tailnet-metrics = {
    description = "Export Headscale tailnet metrics";
    after = ["headscale.service"];
    wants = ["headscale.service"];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${headscaleTailnetMetricsScript}
    '';
  };

  systemd.timers.headscale-tailnet-metrics = {
    description = "Refresh Headscale tailnet metrics";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
      Unit = "headscale-tailnet-metrics.service";
    };
  };

  systemd.tmpfiles.rules = ["d ${headscaleTailnetMetricsDir} 0755 root root -"];
}
