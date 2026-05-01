{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs,
  php,
  dataDir ? "/var/lib/speedtest-tracker",
}: let
  pname = "speedtest-tracker";
  version = "1.14.0";

  src = fetchFromGitHub {
    owner = "alexjustesen";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Jhd1P2i+WDwRiaIDy6rxkouHm/JJAtV6QciXZ/99b68=";
  };

  nodeModules = buildNpmPackage {
    pname = "${pname}-node-modules";
    inherit version src;

    npmDepsHash = "sha256-fi3gbHwEHR04wGm9hlUUlM7SXcz6BLPJbmxfzYIVy+4=";
    dontNpmBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r node_modules "$out/"
      runHook postInstall
    '';
  };

  phpPackage = php.buildEnv {
    extensions = {
      enabled,
      all,
    }:
      enabled
      ++ (with all; [
        bcmath
        curl
        dom
        gd
        intl
        mbstring
        mysqli
        mysqlnd
        opcache
        pcntl
        pdo
        pdo_mysql
        pdo_pgsql
        pdo_sqlite
        pgsql
        posix
        simplexml
        soap
        sqlite3
        xml
        xmlreader
        xmlwriter
        zip
      ]);
  };
in
  php.buildComposerProject {
    inherit pname version src;

    php = phpPackage;
    vendorHash = "sha256-ym+KKxt+cKUfOoJNzh7g5m2CWeCTCcrn5NwNAUU62oU=";

    composerNoPlugins = false;
    composerNoScripts = true;

    nativeBuildInputs = [
      makeWrapper
      nodejs
    ];

    postInstall = ''
      appDir="$out/share/php/${pname}"

      chmod -R u+w "$appDir"
      ln -s ${nodeModules}/node_modules "$appDir/node_modules"

      export HOME="$TMPDIR"
      (cd "$appDir" && npm run build)

      rm "$appDir/node_modules"
      rm -rf "$appDir/storage" "$appDir/bootstrap/cache"

      mkdir -p "$appDir/database"

      ln -s ${dataDir}/.env "$appDir/.env"
      ln -s ${dataDir}/storage "$appDir/storage"
      ln -s ${dataDir}/bootstrap/cache "$appDir/bootstrap/cache"
      ln -sfn ${dataDir}/database/database.sqlite "$appDir/database/database.sqlite"

      makeWrapper ${lib.getExe phpPackage} "$out/bin/speedtest-tracker-artisan" \
        --add-flags "$appDir/artisan"
    '';

    passthru = {
      inherit phpPackage;
    };

    meta = with lib; {
      description = "Self-hosted internet performance tracking application";
      homepage = "https://github.com/alexjustesen/speedtest-tracker";
      license = licenses.mit;
      mainProgram = "speedtest-tracker-artisan";
      platforms = platforms.linux;
    };
  }
