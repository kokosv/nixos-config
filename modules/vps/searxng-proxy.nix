{ lib, ... }: {
  options.vps.searxngProxy = lib.mkOption { type = lib.types.deferredModule; };

  # Tier 1 — tailnet-only, searxng runs on homeserver.
  config.vps.searxngProxy = { ... }: {
    services.nginx.virtualHosts."searxng.vafla.eu" = {
      listenAddresses = [ "100.64.0.1" ];
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "http://100.64.0.5:8095";
        proxyWebsockets = true;
      };
    };
  };
}
