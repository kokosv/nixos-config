{ lib, ... }: {
  options.homeManager.ranger = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.ranger = { pkgs, ... }: {
    home.packages = with pkgs; [ ranger ];
  };
}
