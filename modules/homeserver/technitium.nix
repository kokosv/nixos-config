{ lib, ... }: {
  options.homeserver.technitium = lib.mkOption { type = lib.types.deferredModule; };

  config.homeserver.technitium = {
    services.technitium-dns-server.enable = true;
  };
}
