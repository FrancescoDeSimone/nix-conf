{
  lib,
  buildGoModule,
  inputs,
  ...
}:
buildGoModule {
  pname = "adguard-exporter";
  version = "0-unstable-${inputs."adguard-exporter".shortRev}";

  src = inputs."adguard-exporter";

  vendorHash = "sha256-js6xO/Sv42saeq2W7MWt7q0As6BvjglgothrT/Fv47E=";

  ldflags = ["-s" "-w"];

  meta = with lib; {
    description = "Prometheus exporter for AdGuard Home metrics";
    homepage = "https://github.com/znandev/adguardexporter";
    maintainers = [];
    mainProgram = "adguardexporter";
    license = licenses.mit;
  };
}
