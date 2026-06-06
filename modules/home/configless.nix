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
      fd
      fdupes
      zip
      unzip
      yt-dlp
      ffmpeg
      qalculate-gtk
      bluetui
      lorien # paint
      pavucontrol # audio
      brightnessctl # brightness
      gearlever # appimage manager
      feh # img viewer
      # vimiv-qt # img viewer vim bindings
    ];
  };
}
