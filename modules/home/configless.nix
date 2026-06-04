{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.configless;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ranger
      xclip
      xdotool
      bluetui
      fd
      fdupes
      zip
      unzip
      gcc
      lorien # paint
      pavucontrol # audio
      yt-dlp
      ffmpeg
    ];
  };
}
