{
  services.cron = {
    enable = true;
    systemCronJobs = [
      "*/1 * * * *	root	/home/thinkcentre/duckdns/duck.sh >/dev/null 2>&1"
    ];
  };
}
