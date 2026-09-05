let
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBOniBU67Ms4nRqq/iF+OVLM5Oj9nGNz5GamFfrQbIz root@nixos"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJC595GzeQlQEx/GA4i10xY3VTjegjCVyHQ9Zz2xvPPx"
    # TODO(capricorn): add the capricorn recipient pubkey here once the machine
    # generates an age identity during install, then run `agenix rekey` (or the
    # repo's rekey step) so the .age files also carry capricorn's key.
  ];
in {
  "provider.age".publicKeys = keys;
  "hoarder.age".publicKeys = keys;
  "slskd.age".publicKeys = keys;
  "govd.age".publicKeys = keys;
  "user-password.age".publicKeys = keys;
  "wifi.age".publicKeys = keys;
  "qui.age".publicKeys = keys;
  "lidarr.age".publicKeys = keys;
  "telegram.age".publicKeys = keys;
  "headscale-authkey.age".publicKeys = keys;
  "tailscale-exporter-api-key.age".publicKeys = keys;
  "headplane-cookie-secret.age".publicKeys = keys;
  "chatto-admin.age".publicKeys = keys;
  "gpg-key.age".publicKeys = keys;
  "ytdl-bot.age".publicKeys = keys;
  "deemix-arl.age".publicKeys = keys;
}
