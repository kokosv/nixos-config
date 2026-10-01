{ lib, ... }: {
  options.vps.headplane = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.headplane = { config, ... }: {
    age.secrets.headplane-cookie-secret.file = ../../secrets/headplane-cookie-secret.age;

    services.headplane = {
      enable = true;
      settings = {
        server = {
          host = "127.0.0.1";
          port = 3000;
          cookie_secret_path = config.age.secrets.headplane-cookie-secret.path;
          cookie_secure = true;
          base_url = "https://headplane.vafla.eu";
        };
        # headscale.url, config_path and public_url auto-configure from services.headscale
        integration.proc.enabled = false; # headscale is managed by systemd, not headplane
      };
    };

    services.nginx.virtualHosts."headplane.vafla.eu" = {
      forceSSL = true;
      useACMEHost = "vafla.eu";
      # tailscale subnet only — no public access, no Anubis, no Authentik
      extraConfig = ''
        allow 100.64.0.0/10;
        deny all;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
      };
    };
  };
}
