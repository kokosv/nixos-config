{ lib, ... }: {
  options.vps.prowlarrProxy = lib.mkOption { type = lib.types.deferredModule; };

  # Tier 1 — tailnet-only, Prowlarr runs on homeserver.
  config.vps.prowlarrProxy = { ... }: {
    services.nginx.virtualHosts."prowlarr.vafla.eu" = {
      listenAddresses = [ "100.64.0.1" ];
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "http://100.64.0.5:9696";
        proxyWebsockets = true;
      };
    };
  };
}
