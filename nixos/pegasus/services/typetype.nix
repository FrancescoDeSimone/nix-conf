{
  config,
  lib,
  private,
  pkgs,
  ...
}: let
  serverPort = config.my.services.typetype.port;
  tokenPort = 8081;
  downloaderPort = 18093;
  garagePort = 3900;

  hostAddress = "192.168.106.10";
  localAddress = "192.168.106.11";
  stateDir = "/var/lib/typetype";

  server = pkgs.typetype-server;
  token = pkgs.typetype-token;
  web = pkgs.typetype-web;
  downloader = pkgs.typetype-downloader;

  publicDomain = "typetype.${private.nginx.domain}";
in {
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-typetype"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 root root -"
    "d /var/lib/typetype/token-cache 0777 root root -"
  ];

  systemd.services."container@typetype".serviceConfig.TimeoutStartSec = lib.mkForce "15min";

  containers.typetype = {
    autoStart = true;
    privateNetwork = true;
    inherit hostAddress localAddress;

    bindMounts."${stateDir}" = {
      hostPath = stateDir;
      isReadOnly = false;
    };
    bindMounts.token-image-dot-cache = {
      hostPath = "/var/lib/typetype/token-cache";
      mountPoint = "${token.image}/.cache";
      isReadOnly = false;
    };

    config = {
      config,
      pkgs,
      ...
    }: let
      secrets = "${stateDir}/secrets";
    in {
      users.groups.typetype-runtime = {};
      programs.nix-ld.enable = lib.mkForce false;
      # The Debian-based token image's binaries (bun, Playwright Chromium)
      # use /lib64/ld-linux-x86-64.so.2 as interpreter. NixOS stubs that
      # path with the unresolvable "stub-ld"; point it at the image's own
      # loader (matches the Debian libc in syslibs) at every boot. "L+"
      # replaces the existing symlink (verified: plain "L!" did not).
      systemd.tmpfiles.rules = [
        "L+ /lib64/ld-linux-x86-64.so.2 - - - - ${token.syslibs}/ld-linux-x86-64.so.2"
      ];
      users.users.typetype-server = {
        isSystemUser = true;
        group = "typetype-runtime";
      };
      users.users.typetype-token = {
        isSystemUser = true;
        group = "typetype-runtime";
      };
      users.users.typetype-downloader = {
        isSystemUser = true;
        group = "typetype-runtime";
      };

      systemd.services.typetype-secrets = {
        description = "Generate TypeType secrets";
        before = [
          "garage.service"
          "typetype-garage-init.service"
          "typetype-server.service"
          "typetype-token.service"
          "typetype-downloader.service"
        ];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          s="${secrets}"
          mkdir -p "$s"
          # The host tmpfiles rule recreates the bind target root-owned, so
          # (re)apply the group/permissions on every boot.
          chgrp typetype-runtime "$s" 2>/dev/null || true
          chmod 0750 "$s"

          umask 0077
          ensure_file() {
            if [ ! -s "$1" ]; then
              ${pkgs.openssl}/bin/openssl rand -hex "$2" > "$1"
            fi
          }
          ensure_file "$s/garage_rpc_secret" 32
          ensure_file "$s/garage_admin_token" 32
          ensure_file "$s/youtube_session_encryption_key" 24
          ensure_file "$s/youtube_remote_login_internal_token" 32
          ensure_file "$s/s3_secret_key" 32
          if [ ! -s "$s/s3_access_key" ]; then
            printf 'GK%s' "$(${pkgs.openssl}/bin/openssl rand -hex 12)" > "$s/s3_access_key"
          fi

          for f in youtube_session_encryption_key youtube_remote_login_internal_token; do
            chgrp typetype-runtime "$s/$f"
            chmod 0640 "$s/$f"
          done

          cat > "$s/garage.env" <<EOF
          GARAGE_RPC_SECRET=$(${pkgs.coreutils}/bin/tr -d '\r\n' < "$s/garage_rpc_secret")
          GARAGE_ADMIN_TOKEN=$(${pkgs.coreutils}/bin/tr -d '\r\n' < "$s/garage_admin_token")
          EOF
          cat > "$s/server.env" <<EOF
          BILIBILI_SESSION_ENCRYPTION_KEY=$(${pkgs.coreutils}/bin/tr -d '\r\n' < "$s/youtube_session_encryption_key")
          EOF
          cat > "$s/downloader.env" <<EOF
          S3_ACCESS_KEY=$(${pkgs.coreutils}/bin/tr -d '\r\n' < "$s/s3_access_key")
          S3_SECRET_KEY=$(${pkgs.coreutils}/bin/tr -d '\r\n' < "$s/s3_secret_key")
          DB_PASSWORD=typetype
          EOF
          chmod 0600 "$s"/*.env
        '';
      };

      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_17;
        ensureDatabases = ["typetype" "typetype_downloader"];
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser  auth-method
          local all       all     trust
          host all        all  127.0.0.1/32   trust
        '';
        ensureUsers = [
          {
            name = "typetype";
            ensureDBOwnership = true;
          }
        ];
      };

      systemd.services.typetype-db-init = {
        description = "Initialize TypeType databases";
        after = ["postgresql.service"];
        requires = ["postgresql.service"];
        before = ["typetype-server.service" "typetype-downloader.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig.Type = "oneshot";
        script = ''
          set -eu
          psql="${pkgs.postgresql_17}/bin/psql"
          pg_isready="${pkgs.postgresql_17}/bin/pg_isready"
          until $pg_isready -h 127.0.0.1 -U postgres -d postgres; do
            sleep 1
          done
          exists=$($psql -h 127.0.0.1 -U postgres -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='typetype_downloader'")
          if [ "$exists" != "1" ]; then
            $psql -h 127.0.0.1 -U postgres -d postgres -c 'CREATE DATABASE "typetype_downloader"'
          fi
          $psql -h 127.0.0.1 -U postgres -d postgres -c 'ALTER DATABASE "typetype" OWNER TO "typetype"'
          $psql -h 127.0.0.1 -U postgres -d postgres -c 'ALTER DATABASE "typetype_downloader" OWNER TO "typetype"'
        '';
      };

      users.users.typetype-valkey = {
        isSystemUser = true;
        group = "typetype-valkey";
      };
      users.groups.typetype-valkey = {};

      systemd.services.typetype-valkey = {
        description = "TypeType cache/queue backend (valkey)";
        after = ["network.target"];
        before = ["typetype-server.service" "typetype-downloader.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = toString [
            "${pkgs.valkey}/bin/valkey-server"
            "--port 6379"
            (toString "--bind 127.0.0.1")
            "--maxmemory 2gb"
            "--maxmemory-policy noeviction"
            "--save \"\""
            "--appendonly no"
            "--dir /run/typetype-valkey"
            "--daemonize no"
          ];
          User = "typetype-valkey";
          Group = "typetype-valkey";
          RuntimeDirectory = "typetype-valkey";
          RuntimeDirectoryMode = "0750";
          Restart = "always";
          RestartSec = "3";
          NoNewPrivileges = true;
          PrivateTmp = true;
        };
      };

      services.garage = {
        enable = true;
        package = pkgs.garage;
        environmentFile = "${secrets}/garage.env";
        settings = {
          replication_factor = 1;
          rpc_bind_addr = "[::]:3901";
          rpc_public_addr = "127.0.0.1:3901";
          s3_api = {
            s3_region = "garage";
            api_bind_addr = "[::]:3900";
          };
          admin = {
            api_bind_addr = "[::]:3903";
          };
        };
      };

      systemd.services.garage = {
        after = ["typetype-secrets.service"];
        requires = ["typetype-secrets.service"];
      };

      systemd.services.typetype-garage-init = {
        description = "Bootstrap TypeType Garage layout/bucket/keys";
        after = ["garage.service" "typetype-secrets.service"];
        requires = ["garage.service"];
        before = ["typetype-downloader.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig.Type = "oneshot";
        script = ''
          set -euo pipefail
          # Unit PATHs inside the container may lack coreutils/grep; make the
          # helpers explicit so the wait loop never depends on defaults.
          PATH="${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:$PATH"
          g="${pkgs.garage}/bin/garage"
          # Semantic: the CLI needs the RPC secret in its environment.
          # Plain sourcing does not export, so flip on set -a around both
          # environment files.
          set -a
          . "${secrets}/garage.env"
          . "${secrets}/downloader.env"
          set +a

          retries=0
          until $g status >/dev/null 2>&1; do
            retries=$((retries + 1))
            if [ "$retries" -ge 60 ]; then
              echo "garage status did not become ready after $retries attempts" >&2
              $g status
              exit 1
            fi
            sleep 1
          done

          status_output="$($g status || true)"
          if printf '%s' "$status_output" | grep -q "NO ROLE ASSIGNED"; then
            node_line="$($g node id | head -1)"
            node_id="''${node_line%%@*}"
            $g layout assign -z dc1 -c 20GB "$node_id"
            $g layout apply --version 1
          fi

          if ! $g bucket info "typetype-downloads" >/dev/null 2>&1; then
            $g bucket create "typetype-downloads"
          fi
          if ! $g key info "$S3_ACCESS_KEY" >/dev/null 2>&1; then
            $g key import --yes -n typetype-downloader "$S3_ACCESS_KEY" "$S3_SECRET_KEY"
          fi
          $g bucket allow --read --write --owner --key "$S3_ACCESS_KEY" "typetype-downloads"
        '';
      };

      systemd.services.typetype-server = {
        description = "TypeType API server";
        # Downloader access is attempted lazily, so it only needs to be up for
        # full functionality, not for startup.
        after = [
          "typetype-secrets.service"
          "typetype-db-init.service"
          "typetype-valkey.service"
          "typetype-token.service"
        ];
        requires = ["typetype-db-init.service" "typetype-valkey.service"];
        wantedBy = ["multi-user.target"];
        environment = {
          ALLOWED_ORIGINS = "https://${publicDomain}";
          AUTH_SESSION_TTL_DAYS = "30";
          AUTH_ALLOW_INSECURE_COOKIES = "false";
          DATABASE_URL = "jdbc:postgresql://127.0.0.1:5432/typetype";
          DATABASE_USER = "typetype";
          DATABASE_PASSWORD = "typetype";
          DRAGONFLY_URL = "redis://127.0.0.1:6379";
          GITHUB_REPO = "TypeType-Video/TypeType";
          GITHUB_ISSUE_TEMPLATE = "bug_report_backend.md";
          DOWNLOADER_SERVICE_URL = "http://127.0.0.1:${toString downloaderPort}";
          SUBTITLE_SERVICE_URL = "http://127.0.0.1:${toString tokenPort}";
          YOUTUBE_REMOTE_LOGIN_ENABLED = "false";
          YOUTUBE_REMOTE_LOGIN_SERVICE_URL = "http://127.0.0.1:${toString tokenPort}";
          YOUTUBE_REMOTE_LOGIN_CALLBACK_BASE_URL = "http://127.0.0.1:${toString serverPort}";
          YOUTUBE_REMOTE_LOGIN_INTERNAL_TOKEN_FILE = "${secrets}/youtube_remote_login_internal_token";
          YOUTUBE_SESSION_ENCRYPTION_KEY_FILE = "${secrets}/youtube_session_encryption_key";
          YOUTUBE_REMOTE_LOGIN_TTL_MS = "480000";
          YOUTUBE_REMOTE_LOGIN_MAX_SESSIONS = "2";
          YOUTUBE_REMOTE_LOGIN_MAX_FRAME_BYTES = "524288";
        };
        serviceConfig = {
          ExecStart = toString [
            "${pkgs.jdk25_headless}/bin/java"
            "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
            "-jar ${server}/lib/typetype-server-all.jar"
          ];
          EnvironmentFile = "${secrets}/server.env";
          User = "typetype-server";
          Group = "typetype-runtime";
          Restart = "always";
          RestartSec = "5";
          NoNewPrivileges = true;
        };
      };

      systemd.services.typetype-token = {
        description = "TypeType token service (BotGuard / PO tokens / subtitles)";
        after = ["typetype-secrets.service"];
        before = ["typetype-server.service" "typetype-downloader.service"];
        wantedBy = ["multi-user.target"];
        environment = token.browserEnv
        // {
          DISPLAY = ":99";
          NODE_ENV = "production";
          TYPE_TYPE_BUILD_VERSION = "1.11.1";
          TYPE_TYPE_BUILD_REVISION = "1687097176109ebcb25c52d83d5b1bdf97a75002";
          TYPE_TYPE_BUILD_TIME = "2026-11-01T07:36:51Z";
          YOUTUBE_REMOTE_LOGIN_ENABLED = "false";
          YOUTUBE_REMOTE_LOGIN_INTERNAL_TOKEN_FILE = "${secrets}/youtube_remote_login_internal_token";
          YOUTUBE_REMOTE_LOGIN_CALLBACK_ORIGIN = "http://127.0.0.1:${toString serverPort}";
          YOUTUBE_REMOTE_LOGIN_MAX_SESSIONS = "2";
          YOUTUBE_REMOTE_LOGIN_FRAME_FPS = "10";
          YOUTUBE_REMOTE_LOGIN_MAX_FRAME_BYTES = "524288";
          YOUTUBE_REMOTE_LOGIN_HEADLESS = "false";
          YOUTUBE_REMOTE_LOGIN_DISABLE_AUTOMATION_CONTROLLED = "true";
          YOUTUBE_OUTBOUND_PROXY_URL = "";
          HOME = "/var/lib/typetype-token";
          XDG_CACHE_HOME = "/var/lib/typetype-token/.cache";
        };
        serviceConfig = {
          WorkingDirectory = "${token}/apps/token";
          ExecStart = "${
            pkgs.writeShellScript "typetype-token-start" ''
              set -euo pipefail
              unset LD_LIBRARY_PATH
              rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 /tmp/.X11-unix/X99a
              if [ ! -d /tmp/.X11-unix ]; then
                mkdir -p /tmp/.X11-unix
                chmod 1777 /tmp/.X11-unix
              fi
              ${pkgs.xorg.xvfb}/bin/Xvfb :99 -screen 0 1920x1080x24 -nolisten tcp -ac >/var/lib/typetype-token/xvfb.log 2>&1 &
              xvfb_pid=$!
              attempt=0
              while [ ! -S "/tmp/.X11-unix/X99" ]; do
                if ! kill -0 "$xvfb_pid" 2>/dev/null; then
                  cat /var/lib/typetype-token/xvfb.log >&2
                  exit 1
                fi
                attempt=$((attempt + 1))
                if [ "$attempt" -ge 50 ]; then
                  kill "$xvfb_pid" 2>/dev/null || true
                  exit 1
                fi
                sleep 0.1
              done
              exec ${pkgs.coreutils}/bin/env LD_LIBRARY_PATH="${token.syslibs}" "${token}/bin/bun" dist/index.js
            ''
          }";
          User = "typetype-token";
          Group = "typetype-runtime";
          StateDirectory = "typetype-token";
          Restart = "always";
          RestartSec = "5";
          NoNewPrivileges = true;
        };
      };

      systemd.services.typetype-downloader = {
        description = "TypeType media downloader";
        after = [
          "typetype-secrets.service"
          "typetype-db-init.service"
          "typetype-valkey.service"
          "typetype-garage-init.service"
        ];
        requires = ["typetype-db-init.service" "typetype-valkey.service" "typetype-garage-init.service"];
        wantedBy = ["multi-user.target"];
        environment = {
          HTTP_PORT = toString downloaderPort;
          PUBLIC_BASE_URL = "/api/downloader";
          TYPETYPE_API_BASE = "http://127.0.0.1:${toString serverPort}";
          DB_URL = "jdbc:postgresql://127.0.0.1:5432/typetype_downloader";
          DB_USER = "typetype";
          REDIS_HOST = "127.0.0.1";
          REDIS_PORT = "6379";
          REDIS_QUEUE_KEY = "downloader:queue";
          MAX_CONCURRENT_WORKERS = "2";
          MAX_QUEUE_SIZE = "100";
          JOB_TTL_SECONDS = "600";
          DOWNLOAD_WORKERS = "8";
          DOWNLOAD_CHUNK_SIZE = "10485760";
          DOWNLOAD_RANGE_MODE = "query";
          # Downloads are muxed through libavformat (ffmpeg): the wrapped
          # binary carries PATH + LD_LIBRARY_PATH pointing at the Nix ffmpeg
          # (the /nix/store is shared with the container).
          MUXER = "avformat";
          DOWNLOAD_HTTP2 = "true";
          STORAGE_BACKEND = "s3";
          S3_ENDPOINT = "http://127.0.0.1:${toString garagePort}";
          S3_PUBLIC_ENDPOINT = "http://127.0.0.1:${toString garagePort}";
          S3_REGION = "garage";
          S3_BUCKET = "typetype-downloads";
          S3_ARTIFACT_TTL_SECONDS = "7200";
        };
        serviceConfig = {
          ExecStart = "${downloader}/bin/typetype-downloader";
          EnvironmentFile = "${secrets}/downloader.env";
          User = "typetype-downloader";
          Group = "typetype-runtime";
          # The app creates ./data relative to its working directory
          # ("mkdir data: permission denied" was hit with cwd=/).
          WorkingDirectory = "/var/lib/typetype-downloader";
          StateDirectory = "typetype-downloader";
          Restart = "always";
          RestartSec = "5";
          NoNewPrivileges = true;
        };
      };

      # Fonts for Chromium-rendered BotGuard/remote-login frames.
      fonts.fontconfig.enable = true;
      fonts.packages = [pkgs.noto-fonts];

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [serverPort tokenPort downloaderPort];
      };

      networking.resolvconf.enable = false;
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";

      system.stateVersion = "25.11";
    };
  };
}
