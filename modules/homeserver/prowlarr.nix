{ lib, ... }: {
  options.homeserver.prowlarr = lib.mkOption { type = lib.types.deferredModule; };

  config.homeserver.prowlarr = {
    services.prowlarr = {
      enable = true;
      openFirewall = false;
    };
  };
}
