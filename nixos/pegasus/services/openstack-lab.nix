{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.services.openstack-lab;

  inherit
    (lib)
    escapeShellArg
    makeBinPath
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optionals
    types
    ;

  bootstrapScript = pkgs.writeShellScript "openstack-lab-bootstrap" ''
        set -euo pipefail

        export PATH=${makeBinPath [
      cfg.incusPackage
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gawk
      pkgs.git
      pkgs.openssh
      pkgs.jq
    ]}

        project=${escapeShellArg cfg.project}
        instance=${escapeShellArg cfg.instanceName}
        guest_path='/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/root/.nix-profile/bin:$PATH'

        if ! incus info >/dev/null 2>&1; then
          echo "Incus is not ready" >&2
          exit 1
        fi

        if ! incus --project "$project" info "$instance" >/dev/null 2>&1; then
          incus --project "$project" launch ${escapeShellArg "${cfg.remote}:${cfg.image}"} "$instance"
        fi

        incus --project "$project" config set "$instance" security.nesting=true
        incus --project "$project" config set "$instance" limits.cpu ${escapeShellArg (toString cfg.cpu)}
        incus --project "$project" config set "$instance" limits.memory ${escapeShellArg cfg.memory}

        if ! incus --project "$project" config device show "$instance" | grep -q '^root:$'; then
          incus --project "$project" config device override "$instance" root size=${escapeShellArg cfg.diskSize}
        else
          incus --project "$project" config device set "$instance" root size ${escapeShellArg cfg.diskSize} || true
        fi

        if ! incus --project "$project" config device show "$instance" | grep -q '^kvm:$'; then
          incus --project "$project" config device add "$instance" kvm unix-char source=/dev/kvm path=/dev/kvm
        fi

        if ! incus --project "$project" config device show "$instance" | grep -q '^vhost-net:$'; then
          incus --project "$project" config device add "$instance" vhost-net unix-char source=/dev/vhost-net path=/dev/vhost-net
        fi

        if [ "$(incus --project "$project" list "$instance" --format json | jq -r '.[0].status')" != "Running" ]; then
          incus --project "$project" start "$instance"
        fi

        # Wait until the guest is willing to run commands.
        for _ in $(seq 1 60); do
          if incus --project "$project" exec "$instance" -- sh -lc 'true' >/dev/null 2>&1; then
            break
          fi
          sleep 2
        done

        bridge="$(incus --project "$project" profile device get default eth0 network 2>/dev/null || true)"
        bridge_ipv4_cidr=""
        bridge_ipv4_gateway=""
        bridge_ipv4_prefix=""
        guest_ipv4=""

        if [ -n "$bridge" ]; then
          bridge_ipv4_cidr="$(incus network get "$bridge" ipv4.address 2>/dev/null || true)"
          if [ -n "$bridge_ipv4_cidr" ] && [ "$bridge_ipv4_cidr" != "none" ]; then
            bridge_ipv4_gateway="''${bridge_ipv4_cidr%/*}"
            bridge_ipv4_prefix="''${bridge_ipv4_cidr#*/}"
            if [ "$bridge_ipv4_gateway" != "$bridge_ipv4_cidr" ]; then
              IFS=. read -r octet1 octet2 octet3 _ <<EOF
    $bridge_ipv4_gateway
    EOF
              if [ -n "''${octet1:-}" ] && [ -n "''${octet2:-}" ] && [ -n "''${octet3:-}" ]; then
                guest_ipv4="''${octet1}.''${octet2}.''${octet3}.${toString cfg.ipv4HostOctet}"
              fi
            fi
          fi
        fi

        if [ -n "$guest_ipv4" ] && [ -n "$bridge_ipv4_gateway" ] && [ -n "$bridge_ipv4_prefix" ]; then
          incus --project "$project" exec "$instance" -- sh -lc "
            export PATH=$guest_path
            mkdir -p /etc/systemd/network/50-eth0.network.d
          "

          tmp_network="$(mktemp)"
          cat >"$tmp_network" <<EOF
    [Network]
    Address=$guest_ipv4/$bridge_ipv4_prefix
    Gateway=$bridge_ipv4_gateway
    DNS=$bridge_ipv4_gateway
    DNS=1.1.1.1
    DNS=8.8.8.8
    EOF
          incus --project "$project" file push "$tmp_network" "$instance/etc/systemd/network/50-eth0.network.d/10-openstack-lab.conf"
          rm -f "$tmp_network"

          incus --project "$project" exec "$instance" -- sh -lc "
            export PATH=$guest_path
            chmod 0644 /etc/systemd/network/50-eth0.network.d/10-openstack-lab.conf
            systemctl restart systemd-networkd systemd-resolved
          "

          for _ in $(seq 1 30); do
            if incus --project "$project" exec "$instance" -- sh -lc "
              export PATH=$guest_path
              [ -n \"\$(ip -4 route show default 2>/dev/null)\" ] && getent hosts channels.nixos.org >/dev/null 2>&1
            " >/dev/null 2>&1; then
              break
            fi
            sleep 2
          done
        fi

        incus --project "$project" exec "$instance" -- sh -lc "
          export PATH=$guest_path
          mkdir -p /root/.config/nix /root/src /root/work
          conf=/root/.config/nix/nix.conf
          touch \"\$conf\"
          grep -qxF 'experimental-features = nix-command flakes' \"\$conf\" || printf '%s\\n' 'experimental-features = nix-command flakes' >> \"\$conf\"
          grep -qxF 'accept-flake-config = true' \"\$conf\" || printf '%s\\n' 'accept-flake-config = true' >> \"\$conf\"
          grep -qxF 'sandbox = false' \"\$conf\" || printf '%s\\n' 'sandbox = false' >> \"\$conf\"
          export NIX_CONFIG='sandbox = false'
          nix-channel --update nixos
          export NIX_PATH=nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos
          if ! command -v git >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1 || ! command -v tmux >/dev/null 2>&1 || ! command -v ssh >/dev/null 2>&1; then
            nix-env -f '<nixpkgs>' -iA git jq tmux openssh
          fi
          if [ ! -d /root/src/openstack-nix ]; then
            git clone ${escapeShellArg cfg.repoUrl} /root/src/openstack-nix
          fi
        "
  '';

  destroyScript = pkgs.writeShellScript "openstack-lab-destroy" ''
    set -euo pipefail
    export PATH=${makeBinPath [cfg.incusPackage pkgs.coreutils]}

    project=${escapeShellArg cfg.project}
    instance=${escapeShellArg cfg.instanceName}

    if incus --project "$project" info "$instance" >/dev/null 2>&1; then
      incus --project "$project" stop "$instance" --force || true
      incus --project "$project" delete "$instance" || true
    fi
  '';
in {
  options.my.services.openstack-lab = {
    enable = mkEnableOption "isolated NixOS Incus container used to hack on openstack-nix";

    incusPackage = mkPackageOption pkgs "incus-lts" {};

    instanceName = mkOption {
      type = types.str;
      default = "openstack-lab";
    };

    project = mkOption {
      type = types.str;
      default = "user-1000";
    };

    remote = mkOption {
      type = types.str;
      default = "images";
    };

    image = mkOption {
      type = types.str;
      default = "nixos/25.11";
    };

    repoUrl = mkOption {
      type = types.str;
      default = "https://github.com/FrancescoDeSimone/openstack-nix";
    };

    cpu = mkOption {
      type = types.int;
      default = 8;
    };

    memory = mkOption {
      type = types.str;
      default = "20GiB";
    };

    diskSize = mkOption {
      type = types.str;
      default = "120GiB";
    };

    ipv4HostOctet = mkOption {
      type = types.int;
      default = 50;
    };

    autoStart = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    systemd.services.openstack-lab-container = {
      description = "Ensure the OpenStack lab Incus NixOS container exists";
      after = ["incus.service" "network-online.target"];
      wants = ["incus.service" "network-online.target"];
      wantedBy = optionals cfg.autoStart ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = bootstrapScript;
      };
    };

    environment.systemPackages = [
      cfg.incusPackage
      (pkgs.writeShellScriptBin "openstack-lab-shell" ''
        exec ${cfg.incusPackage}/bin/incus --project ${escapeShellArg cfg.project} exec ${escapeShellArg cfg.instanceName} -- bash
      '')
      (pkgs.writeShellScriptBin "openstack-lab-start" ''
        exec ${bootstrapScript}
      '')
      (pkgs.writeShellScriptBin "openstack-lab-stop" ''
        exec ${cfg.incusPackage}/bin/incus --project ${escapeShellArg cfg.project} stop ${escapeShellArg cfg.instanceName} "$@"
      '')
      (pkgs.writeShellScriptBin "openstack-lab-delete" ''
        exec ${destroyScript}
      '')
    ];
  };
}
