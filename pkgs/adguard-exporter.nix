{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}:
buildGoModule {
  pname = "adguard-exporter";
  version = "unstable-2026-04-08";

  src = fetchFromGitHub {
    owner = "znandev";
    repo = "adguardexporter";
    rev = "e462d07311afe1787fa244c67081c034f2e1134e";
    hash = "sha256-Pvw7mcnBdtlCT3ioSAlM6EjfPNW490nK1Pu3LQ+1YUU=";
  };

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
