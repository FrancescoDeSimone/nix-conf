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

  vendorHash = "sha256-TmEAaScJxj63r5bQH2dLiVbWQ7UUQBlG34evEdmYVMM=";

  ldflags = ["-s" "-w"];

  meta = with lib; {
    description = "Prometheus exporter for AdGuard Home metrics";
    homepage = "https://github.com/znandev/adguardexporter";
    maintainers = [];
    mainProgram = "adguardexporter";
    license = licenses.mit;
  };
}
