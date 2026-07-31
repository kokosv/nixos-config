{ lib, pkgs, ... }: {
  options.nixos.greenclip = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.greenclip = {
    environment.systemPackages = with pkgs; [ haskellPackages.greenclip ];
    services.greenclip.enable = true;
  };
}
