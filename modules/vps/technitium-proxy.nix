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
      };
    };
  };
}
