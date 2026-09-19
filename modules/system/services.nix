{ lib, ... }: {
  options.nixos.services = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.services = {
    systemd.services = {
    };
  };
}
