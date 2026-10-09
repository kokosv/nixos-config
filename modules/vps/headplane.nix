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
      listenAddresses = [ "100.64.0.1" ];
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
        extraConfig = ''
          auth_request /outpost.goauthentik.io/auth/nginx;
          error_page 401 = @authentik_redirect;
          auth_request_set $auth_cookie $upstream_http_set_cookie;
          add_header Set-Cookie $auth_cookie;
          auth_request_set $authentik_username $upstream_http_x_authentik_username;
          auth_request_set $authentik_groups   $upstream_http_x_authentik_groups;
          proxy_set_header X-authentik-username $authentik_username;
          proxy_set_header X-authentik-groups   $authentik_groups;
        '';
      };
      locations."/outpost.goauthentik.io/" = {
        proxyPass = "http://<authentik-tailnet-ip>:9000/outpost.goauthentik.io/";
        extraConfig = ''
          proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
          add_header Set-Cookie $auth_cookie;
          auth_request_set $auth_cookie $upstream_http_set_cookie;
        '';
      };
      locations."@authentik_redirect" = {
        extraConfig = ''
          return 302 /outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
        '';
      };
    };
  };
}
