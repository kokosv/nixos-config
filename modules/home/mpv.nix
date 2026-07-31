{ lib, ... }: {
  options.homeManager.mpv = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.mpv = { pkgs, ... }: {
    home.packages = with pkgs; [ mpv ];

    programs.mpv = {
      enable = true;

      config = {
        volume = 80;
        loop-file = "no";
        sub-auto = "fuzzy";
        keep-open = "yes";

        hwdec = "vaapi";
        vo = "gpu";
        gpu-context = "x11egl";

        ytdl-raw-options = "no-playlist=";
        ytdl-raw-options-append = "cookies-from-browser=firefox";
      };
    };
  };
}
