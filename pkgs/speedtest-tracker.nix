{
  lib,
  stdenvNoCC,
  fetchNpmDeps,
  buildPackages,
  inputs,
  nodejs,
  php84,
  dataDir ? "/var/lib/speedtest-tracker",
}: let
  pname = "speedtest-tracker";
  version = "0.0.0";
  composerVersion = "dev-main";
  src = inputs."speedtest-tracker";
  phpPackage = php84;
in
  stdenvNoCC.mkDerivation {
    inherit pname version src;

    buildInputs = [phpPackage];

    nativeBuildInputs = [
      nodejs
      buildPackages.npmHooks.npmConfigHook
      phpPackage.packages.composer
      phpPackage.composerHooks2.composerInstallHook
    ];

    preConfigure = ''
      export COMPOSER_ROOT_VERSION="${composerVersion}"
    '';

    composerVendor = phpPackage.mkComposerVendor {
      inherit pname src;
      version = composerVersion;
      composerNoScripts = true;
      composerNoPlugins = false;
      composerStrictValidation = false;
      strictDeps = true;
      vendorHash = "sha256-YevX7FazqP4ccjo6pmNSDGc/o3+pHjW7mC6QvCrp6Oc=";
    };

    npmDeps = fetchNpmDeps {
      inherit src;
      name = "${pname}-npm-deps";
      hash = "sha256-IeNhs5YdYtdsezNWTDXpqnaLUL5iJhhdV0vM+IW0opo=";
    };

    composerNoScripts = true;

    buildPhase = ''
      runHook preBuild

      rm -rf vendor
      cp -r "$composerVendor/vendor" ./vendor
      chmod -R +w vendor
      composer dump-autoload --no-scripts --working-dir="$PWD"
      npm run build

      runHook postBuild
    '';

    postInstall = ''
      appDir="$out/share/php/${pname}"

      chmod -R u+w "$appDir"
      rm -rf "$appDir/storage" "$appDir/bootstrap/cache"

      mkdir -p "$appDir/database"

      ln -s ${dataDir}/.env "$appDir/.env"
      ln -s ${dataDir}/storage "$appDir/storage"
      ln -s ${dataDir}/bootstrap/cache "$appDir/bootstrap/cache"
      ln -sfn ${dataDir}/database/database.sqlite "$appDir/database/database.sqlite"
    '';

    passthru = {
      inherit phpPackage;
    };

    meta = with lib; {
      description = "Self-hosted internet performance tracking application";
      homepage = "https://github.com/alexjustesen/speedtest-tracker";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  }
