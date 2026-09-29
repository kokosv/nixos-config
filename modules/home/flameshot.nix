{ lib, ... }: {
  options.homeManager.flameshot = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.flameshot = { pkgs, config, ... }: {
    home.packages = with pkgs; [ flameshot ];

    systemd.user.tmpfiles.rules = [
      "d %h/pic/scr 0755 - - -"
    ];

    services.flameshot = {
      enable = true;

      settings = {
        General = {
          savePath = "${config.home.homeDirectory}/pic/scr";
          saveAsFileExtension = ".png";
          drawColor = "#ffffff";
          showHelp = false;
          showSidePanelButton = false;
          showDesktopNotification = false;
          showAbortNotification = false;
          filenamePattern = "%Y-%m-%d-%H-%M-%S";
          disabledTrayIcon = true;
          autoCloseIdleDaemon = true;
          startupLaunch = false;
          showStartupLaunchMessage = false;
          contrastOpacity = 150; # 0-255
          antialiasingPinZoom = true;
        };
      };
    };
  };
}
