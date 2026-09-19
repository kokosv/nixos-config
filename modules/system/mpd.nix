{ lib, ... }: {
  options.nixos.mpd = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.mpd = {
    services.mpd = {
      enable = true;
      startWhenNeeded = true;
      settings.audio_output = [{ type = "alsa"; name = "ALSA Output"; }];
    };
  };
}
