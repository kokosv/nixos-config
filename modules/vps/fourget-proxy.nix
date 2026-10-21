{ lib, ... }: {
  options.vps.fourgetProxy = lib.mkOption { type = lib.types.deferredModule; };

  # Tier 1 — tailnet-only, 4get runs on homeserver.
  config.vps.fourgetProxy = { ... }: {
    services.nginx.virtualHosts."tursi.vafla.eu" = {
      listenAddresses = [ "100.64.0.1" ];
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "http://100.64.0.5:8098";
        proxyWebsockets = true;
      };
    };
  };
}
