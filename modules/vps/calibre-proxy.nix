{ lib, ... }: {
  options.vps.calibreProxy = lib.mkOption { type = lib.types.deferredModule; };

  # Tier 1 — tailnet-only, calibre-server runs on homeserver.
  config.vps.calibreProxy = { ... }: {
    services.nginx.virtualHosts."knigi.vafla.eu" = {
      listenAddresses = [ "100.64.0.1" ];
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "http://100.64.0.5:8081";
        proxyWebsockets = true;
      };
    };
  };
}
