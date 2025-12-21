{
  services.ntopng = {
    enable = true;
    interfaces = [ "any" ];
    httpPort = 7777;
    extraConfig = ''
      --disable-login=1
    '';
  };
}
