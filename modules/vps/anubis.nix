{ lib, ... }: {
  options.vps.anubis = lib.mkOption { type = lib.types.deferredModule; };

  # All public-tier nginx vhosts live here alongside their Anubis instance.
  # Exempt from Anubis: headscale (API clients fail PoW), headplane (tailnet-only).
  # When adding a new public service: add an instances.<name> entry + virtualHost below.
  config.vps.anubis = { ... }: {

    # nginx needs to read the anubis unix sockets
    users.users.nginx.extraGroups = [ "anubis" ];

    # DIFFICULTY=4 alone does nothing once useDefaultBotRules pulls in Anubis's
    # built-in weight-threshold tiers — those hardcode their own per-tier difficulty
    # and override the global setting. Normal browsers land in "moderate-suspicion"
    # (weight 10-20), which defaults to difficulty 2. Override the whole tier list
    # here, globally, to bump that to 4 — same structure as Anubis's own defaults,
    # just with moderate-suspicion raised.
    services.anubis.defaultOptions.policy.settings.thresholds = [
      {
        name = "minimal-suspicion";
        expression = "weight <= 0";
        action = "ALLOW";
      }
      {
        name = "mild-suspicion";
        expression.all = [ "weight > 0" "weight < 10" ];
        action = "CHALLENGE";
        challenge = {
          algorithm = "metarefresh";
          difficulty = 1;
        };
      }
      {
        name = "moderate-suspicion";
        expression.all = [ "weight >= 10" "weight < 20" ];
        action = "CHALLENGE";
        challenge = {
          algorithm = "fast";
          difficulty = 4; # was 2 in Anubis's built-in default
        };
      }
      {
        name = "mild-proof-of-work";
        expression.all = [ "weight >= 20" "weight < 30" ];
        action = "CHALLENGE";
        challenge = {
          algorithm = "fast";
          difficulty = 4;
        };
      }
      {
        name = "extreme-suspicion";
        expression = "weight >= 30";
        action = "CHALLENGE";
        challenge = {
          algorithm = "fast";
          difficulty = 6;
        };
      }
    ];

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
