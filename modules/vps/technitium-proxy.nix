{ lib, ... }: {
  options.vps.technitiumProxy = lib.mkOption { type = lib.types.deferredModule; };

  # Tier 1 — tailnet-only, Technitium's web UI runs on homeserver.
  config.vps.technitiumProxy = { ... }: {
    services.nginx.virtualHosts."dns.vafla.eu" = {
      listenAddresses = [ "100.64.0.1" ];
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "http://100.64.0.5:5380";
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
        proxyPass = "http://100.64.0.5:9000/outpost.goauthentik.io/";
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
