{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.mpv;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ mpv ];

    programs.mpv = {
      enable = true;

      config = {
        volume = 80;
        loop-file = "no";
        sub-auto = "fuzzy";
        keep-open = "yes";

        ytdl-raw-options = "no-playlist=";
        ytdl-raw-options-append = "cookies-from-browser=firefox";
      };

    };

  };
}
