{
  config,
  private,
  ...
}: {
  imports = [../../../modules/nixos/opengym];

  my.services.opengym = {
    enable = true;
    # Behind the same-host nginx vhost: the sign-in throttle reads the client
    # address from X-Forwarded-For.
    trustProxy = true;
    firstUserAdmin = true;
    # Name/e-mail + password sign-in next to passkeys.
    passwordLogin = true;
    # Registering needs an invite code issued by the admin dashboard.
    inviteOnly = true;
    adminUids = "RcpaXF01DsbfJSni";
  };
}
