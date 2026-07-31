{ lib, ... }: {
  options.nixos.trackpoint = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.trackpoint = {
    hardware.trackpoint = {
      enable = true;
      device = "TPPS/2 IBM TrackPoint";
      emulateWheel = true;
      sensitivity = 255;
      speed = 255;
    };
  };
}
