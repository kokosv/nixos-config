{ lib, pkgs, ... }: {
  options.nixos.upower = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.upower = {
    environment.systemPackages = with pkgs; [ upower ];
    services.upower = {
      enable = true;
      noPollBatteries = true;
    };
  };
}
