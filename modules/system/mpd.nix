{ config, pkgs, lib, ... }:

let
  cfg = config.modules.mpd;
in {
  config = lib.mkIf cfg.enable {
    services.mpd = {
      enable = true;
      startWhenNeeded = true;

      settings = {
        audio_output = [
          {
            type = "alsa";
            name = "ALSA Output";
          }
        ];
      };
    };
  };
}
