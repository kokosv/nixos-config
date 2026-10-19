{ lib, ... }: {
  options.vps.qbittorrentProxy = lib.mkOption { type = lib.types.deferredModule; };

  # Tier 1 — tailnet-only, qbittorrent runs on homeserver.
  config.vps.qbittorrentProxy = { ... }: {
    services.nginx.virtualHosts."torrent.vafla.eu" = {
      listenAddresses = [ "100.64.0.1" ];
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "http://100.64.0.5:8090";
        proxyWebsockets = true;
      };
    };
  };
}
