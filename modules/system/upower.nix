{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.upower;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ upower ];

    services.upower = {
      enable = true;

      noPollBatteries = true;
    };

  };
}
