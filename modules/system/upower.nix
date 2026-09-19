{ lib, ... }: {
  options.nixos.upower = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.upower = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [ upower ];
    services.upower = {
      enable = true;
      noPollBatteries = true;
    };
  };
}
