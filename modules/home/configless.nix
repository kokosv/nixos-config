{ lib, ... }: {
  options.homeManager.configless = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.configless = { pkgs, ... }: {
    home.packages = with pkgs; [
      xclip
      xdotool
      fd
      fdupes
      zip
      unzip
      yt-dlp
      ffmpeg
      inotify-tools
      libnotify
      coreutils
      yad

      qalculate-gtk
      bluetui
      lorien # paint
      pavucontrol # audio
      brightnessctl # brightness
      gearlever # appimage manager
      feh # img viewer
      # vimiv-qt # img viewer vim bindings
      claude-code
      suckit # recursive website content download
    ];
  };
}
