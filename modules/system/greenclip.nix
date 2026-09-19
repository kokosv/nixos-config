{ lib, ... }: {
  options.nixos.greenclip = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.greenclip = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [ haskellPackages.greenclip ];
    services.greenclip.enable = true;
  };
}
