{pkgs, ...}: {
  systemd.tmpfiles.rules = [
    "d /data/kasm 0775 microvm kvm -"
  ];

  networking.interfaces."tap-kasmweb" = {
    virtual = true;
    virtualType = "tap";
    ipv4.addresses = [
      {
        address = "192.168.120.10";
        prefixLength = 24;
      }
    ];
  };
  networking.nat = {
    enable = true;
    internalInterfaces = ["tap-kasmweb"];
    externalInterface = "eno1";
    enableIPv6 = true;
    forwardPorts = [
      {
        proto = "tcp";
        sourcePort = 8443;
        destination = "192.168.120.11:443";
      }
    ];
  };

  microvm.vms.kasmweb = {
    autostart = true;

    config = {
      boot.initrd.kernelModules = [
        "vsock"
        "vmw_vsock_virtio_transport_common"
        "vmw_vsock_virtio_transport"
      ];
      networking.interfaces.eth0.ipv4.addresses = [
        {
          address = "192.168.120.11";
          prefixLength = 24;
        }
      ];

      networking.defaultGateway = {
        address = "192.168.120.10";
        interface = "eth0";
      };

      networking.nameservers = ["8.8.8.8"];

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [443];
      };

      services.kasmweb = {
        enable = true;
      };

      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJC595GzeQlQEx/GA4i10xY3VTjegjCVyHQ9Zz2xvPPx"
      ];

      nixpkgs.config = pkgs.lib.mkForce {};
      system.stateVersion = "25.11";
      networking.hostName = "kasmweb-vm";

      microvm = {
        hypervisor = "qemu";
        vcpu = 4;
        mem = 4096;
        vsock.cid = 100;
        vsock.ssh.enable = true;
        interfaces = [
          {
            type = "tap";
            id = "tap-kasmweb";
            mac = "02:00:00:00:00:01";
          }
        ];
        volumes = [
          {
            mountPoint = "/var/lib";
            image = "/data/kasm/kasmweb-storage.img";
            size = 50000; # 50 GB
          }
        ];
      };
    };
  };

  systemd.services."microvm-tap-interfaces@kasmweb".serviceConfig.ExecStartPost = [
    "${pkgs.iproute2}/bin/ip addr replace 192.168.120.10/24 dev tap-kasmweb"
  ];
}
