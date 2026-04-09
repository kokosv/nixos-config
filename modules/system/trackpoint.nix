{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.trackpoint;
in
{
  config = lib.mkIf cfg.enable {

    hardware.trackpoint = {
      enable = true;
      device = "TPPS/2 IBM TrackPoint";
      emulateWheel = true;
      sensitivity = 255; # 128 default - 255 max
      speed = 255; # 97 default - 255 max
    };
  };
}
