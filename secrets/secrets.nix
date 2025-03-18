let
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBOniBU67Ms4nRqq/iF+OVLM5Oj9nGNz5GamFfrQbIz root@nixos"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJC595GzeQlQEx/GA4i10xY3VTjegjCVyHQ9Zz2xvPPx"
  ];
in {
  "provider.age".publicKeys = keys;
  "hoarder.age".publicKeys = keys;
}
