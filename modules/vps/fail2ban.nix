{ lib, ... }: {
  options.vps.fail2ban = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.fail2ban = {
    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      bantime-increment.enable = true;
      jails = {
        sshd.settings = {
          enabled = true;
          port = "22";
          filter = "sshd";
          maxretry = 4;
        };
        nginx-http-auth.settings = {
          enabled = true;
          filter = "nginx-http-auth";
          logpath = "/var/log/nginx/error.log";
        };
        nginx-botsearch.settings = {
          enabled = true;
          filter = "nginx-botsearch";
          logpath = "/var/log/nginx/access.log";
        };
      };
    };
  };
}
