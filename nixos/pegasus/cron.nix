{ private, ... }:
let
  provider = private.nginx.provider;
in
{
  services.cron = {
    enable = true;
    systemCronJobs = [
      "*/1 * * * *	root	/home/thinkcentre/${provider}/${provider}.sh >/dev/null 2>&1"
    ];
  };
}
