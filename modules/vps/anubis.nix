{ lib, ... }: {
  options.vps.anubis = lib.mkOption { type = lib.types.deferredModule; };

  # All public-tier nginx vhosts live here alongside their Anubis instance.
  # Exempt from Anubis: headscale (API clients fail PoW), headplane (tailnet-only).
  # When adding a new public service: add an instances.<name> entry + virtualHost below.
  config.vps.anubis = { ... }: {

    # nginx needs to read the anubis unix sockets
    users.users.nginx.extraGroups = [ "anubis" ];

    # ── Gatus (bachkali.vafla.eu) ───────────────────────────────────────────
    services.anubis.instances.gatus = {
      settings = {
        TARGET = "http://localhost:8081";
        BIND = "/run/anubis/anubis-gatus/anubis.sock";
        DIFFICULTY = 4;
      };
    };
    services.nginx.virtualHosts."bachkali.vafla.eu" = {
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "http://unix:/run/anubis/anubis-gatus/anubis.sock";
        extraConfig = ''
          if ($geo_blocked) { return 403; }
        '';
      };
    };

    # ── Authentik login portal (auth.vafla.eu) ──────────────────────────────
    # Public + tailnet reachable — the shared SSO login surface tier-0c public
    # apps and tier-1 tailnet apps redirect to. No auth_request wrapper here —
    # this IS Authentik, gating it behind itself would be circular.
    services.anubis.instances.auth = {
      settings = {
        TARGET = "http://100.64.0.5:9000"; # authentik-server on homeserver, over tailnet
        BIND = "/run/anubis/anubis-auth/anubis.sock";
        DIFFICULTY = 4;
      };
    };
    services.nginx.virtualHosts."auth.vafla.eu" = {
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "http://unix:/run/anubis/anubis-auth/anubis.sock";
        proxyWebsockets = true;
        extraConfig = ''
          if ($geo_blocked) { return 403; }
        '';
      };
    };

    # ── Enclosed (taina.vafla.eu) ────────────────────────────────────────────
    services.anubis.instances.taina = {
      settings = {
        TARGET = "http://100.64.0.5:8787"; # enclosed on homeserver, over tailnet
        BIND = "/run/anubis/anubis-taina/anubis.sock";
        DIFFICULTY = 4;
      };
    };
    services.nginx.virtualHosts."taina.vafla.eu" = {
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "http://unix:/run/anubis/anubis-taina/anubis.sock";
        extraConfig = ''
          if ($geo_blocked) { return 403; }
        '';
      };
    };

    # ── future public services go here ──────────────────────────────────────
    # services.anubis.instances.<name> = {
    #   settings = {
    #     TARGET = "http://127.0.0.1:<port>";
    #     BIND = "/run/anubis/anubis-<name>/anubis.sock";
    #     DIFFICULTY = 4;
    #   };
    # };
    # services.nginx.virtualHosts."<name>.vafla.eu" = {
    #   forceSSL = true;
    #   useACMEHost = "vafla.eu";
    #   locations."/" = {
    #     proxyPass = "http://unix:/run/anubis/anubis-<name>/anubis.sock";
    #     extraConfig = ''
    #       if ($geo_blocked) { return 403; }
    #     '';
    #   };
    # };

  };
}
