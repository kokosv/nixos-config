{ lib, ... }: {
  options.vps.agenix = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.agenix = { inputs, ... }: {
    imports = [ inputs.agenix.nixosModules.default ];
  };
}
