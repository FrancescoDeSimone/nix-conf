# TypeType — self-hosted video platform for YouTube/BiliBili/NicoNico
# (github.com/TypeType-Video). Everything runs inside one nspawn container:
# PostgreSQL 17 (main + downloader DB), valkey (redis-compatible cache/queue
# instead of upstream's dragonfly), Garage (S3 for download artifacts, like
# upstream) and the three services. The host nginx serves the extracted
# frontend dist and proxies /api to the container (services/nginx.nix).
#
# Packaging lives in pkgs/typetype-*.nix:
#   - typetype-server  = shadowJar extracted from the digest-pinned image,
#                        run on JDK 25 exactly like the upstream entrypoint
#     (`java -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -jar app.jar`)
#   - typetype-token   = bun bundle + Playwright chromium from the pinned
#                        mcr playwright runner image (BotGuard needs a real
#                        browser under Xvfb, remote login disabled by default)
#   - typetype-web     = frontend dist, served by host nginx
#   - typetype-downloader = source build (buildGoModule); upstream image
#       pins Go 1.27 + CGO/ffmpeg, mirrored here via go_1_27
{
  config,
  private,
  pkgs,
  ...
}: let
  # Registry entry (ports.nix) labels the container-internal API port.
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
  # Outbound NAT for container services hitting YouTube/BiliBili/NicoNico
  # (same arrangement as the traccar/opencloud containers).
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-typetype"];
    externalInterface = "eno1";
    enableIPv6 = true;
  };

  systemd.tmpfiles.rules = [
    # Only the shared state (secrets, garage bootstrap state) is host-visible.
    # Service persistence (postgres, valkey, garage data) lives inside the
    # container's rootfs like traccar/opencloud.
    "d ${stateDir} 0750 root root -"
  ];

  containers.typetype = {
    autoStart = true;
    privateNetwork = true;
    inherit hostAddress localAddress;

    bindMounts."${stateDir}" = {
      hostPath = stateDir;
      isReadOnly = false;
    };

    config = {
      config,
      pkgs,
      ...
    }: let
      secrets = "${stateDir}/secrets";
    in {
      # --- Shared group + dedicated service users: static UIDs keep /tmp X
      # lock cleanup safe across restarts (sticky bit) ---
      users.groups.typetype-runtime = {};
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

      # --- Secrets: generated once, referenced by env files afterwards ---
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

          # Service-contained file secrets (read via _FILE by the JVM/token
          # services): group-readable, root-owned.
          for f in youtube_session_encryption_key youtube_remote_login_internal_token; do
            chgrp typetype-runtime "$s/$f"
            chmod 0640 "$s/$f"
          done

          # systemd EnvironmentFiles (parsed by root before dropping privileges).
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

      # --- PostgreSQL 17: main DB + downloader DB (trust auth, container-
      # local only; same pattern as the traccar container) ---
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

      # Upstream's init container creates the downloader DB owned by the
      # same role; ensureUsers only owns the matching-name database.
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

      # --- valkey (dragonfly replacement): cache for the server and the
      # download job queue (no persistence, like dragonfly --cache_mode) ---
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

      # --- Garage (S3): download artifact storage, like upstream ---
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

      # Mirror of upstream scripts/bootstrap-garage.sh: layout, bucket,
      # importer key, permissions — all idempotent.
      systemd.services.typetype-garage-init = {
        description = "Bootstrap TypeType Garage layout/bucket/keys";
        after = ["garage.service" "typetype-secrets.service"];
        requires = ["garage.service"];
        before = ["typetype-downloader.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig.Type = "oneshot";
        script = ''
          set -euo pipefail
          . "${secrets}/garage.env"
          . "${secrets}/downloader.env"
          g="${pkgs.garage}/bin/garage"

          for _ in $(seq 1 60); do
            if $g status >/dev/null 2>&1; then break; fi
            sleep 1
          done
          $g status >/dev/null

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

      # --- The three application services ---
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

      # Chromium (BotGuard) runs non-headless under Xvfb exactly like the
      # upstream docker-entrypoint.sh.
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
              rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 /tmp/.X11-unix/X99a
              mkdir -p /tmp/.X11-unix
              chmod 1777 /tmp/.X11-unix
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
              exec "${token}/bin/bun" dist/index.js
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
        # Host nginx reaches the server (public API/UI) and downloader
        # (/api/downloader); the token stays container-internal except its
        # /api/version endpoint, which is also served publicly.
        allowedTCPPorts = [serverPort tokenPort downloaderPort];
      };

      networking.resolvconf.enable = false;
      environment.etc."resolv.conf".text = "nameserver 8.8.8.8";

      system.stateVersion = "25.11";
    };
  };
}
