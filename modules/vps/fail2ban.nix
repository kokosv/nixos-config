{ lib, ... }: {
  options.vps.fail2ban = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.fail2ban = {
    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      bantime-increment.enable = true;
      # Never ban tailnet traffic — already trusted at the firewall layer anyway.
      ignoreIP = [ "100.64.0.0/10" ];
      jails = {
        sshd.settings = {
          enabled = true;
          port = "22";
          filter = "sshd";
          maxretry = 4;
        };
        # backend = "polling" is required for all nginx jails: nginx logs to files
        # (access.log/error.log), not stdout, so the default systemd-journal backend
        # never sees these lines — it only captures what nginx.service prints to its
        # own stdout/stderr, which is basically nothing. sshd is unaffected (NixOS's
        # openssh genuinely logs via journald) and correctly uses the default.
        nginx-http-auth.settings = {
          enabled = true;
          filter = "nginx-http-auth";
          logpath = "/var/log/nginx/error.log";
          backend = "polling";
        };
        nginx-botsearch.settings = {
          enabled = true;
          filter = "nginx-botsearch";
          logpath = "/var/log/nginx/access.log";
          backend = "polling";
        };
        # Enclosed (taina.vafla.eu) has its own login, no Authentik — this covers
        # brute-forcing it. Reuse this pattern for other Authentik-exempt services.
        nginx-enclosed = {
          settings = {
            enabled = true;
            logpath = "/var/log/nginx/access.log";
            backend = "polling";
            maxretry = 5;
          };
          filter.Definition = {
            failregex = ''^<HOST> .*"POST /api/auth/login HTTP/\d\.\d" 401'';
            ignoreregex = "";
          };
        };
      };
    };
  };
}
