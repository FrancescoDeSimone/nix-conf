{
  config,
  private,
  ...
}: {
  imports = [../../../modules/nixos/opengym];

  my.services.opengym = {
    enable = true;
    trustProxy = true;
    firstUserAdmin = true;
    passwordLogin = true;
    inviteOnly = true;
    adminUids = "RcpaXF01DsbfJSni";
  };
}
