{ lib, ... }: {
  options.vps.headscale = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.headscale = { pkgs, inputs, ... }: {
    services.headscale = {
      enable = true;
      package = inputs.headscale.packages.${pkgs.system}.headscale;
      address = "0.0.0.0";
      port = 8080;
      settings = {
        server_url = "https://headscale.vafla.eu";
        dns = {
          base_domain = "tailnet.vafla.eu";
          # Technitium is the sole resolver — see §10 in the architecture doc.
          nameservers.global = [ "100.64.0.5" ];
        };
        derp.server = {
          enabled = true;
          region_id = 999;
          region_code = "home";
          region_name = "Home";
          stun_listen_addr = "0.0.0.0:3478";
        };
        # Fallback to Tailscale's public DERP relays when the self-hosted "Home"
        # region is unreachable (e.g. mobile carrier CGNAT dropping the UDP/STUN
        # path) — these only ever carry opaque end-to-end-encrypted WireGuard
        # packets, not a control-plane dependency. Without this, there's no relay
        # to fall back to and clients get stuck until a manual VPN toggle.
        derp.urls = [ "https://controlplane.tailscale.com/derpmap/default" ];
      };
    };

    services.nginx.virtualHosts."headscale.vafla.eu" = {
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };
      # DERP relay connections are long-lived, not request/response — the global
      # recommendedProxySettings 60s proxy_read_timeout was killing them every
      # minute, forcing constant client reconnects (seen as "no-derp-connection"
      # health warnings on tailnet devices).
      locations."/derp" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_read_timeout 1d;
          proxy_send_timeout 1d;
        '';
      };
    };
  };
}
