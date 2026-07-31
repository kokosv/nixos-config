{ lib, pkgs, ... }: {
  options.nixos.i3 = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.i3 = {
    environment.systemPackages = with pkgs; [ i3 ];
    services.xserver.windowManager.i3.enable = true;
  };
}
