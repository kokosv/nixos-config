{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.flameshot;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ flameshot ];

    services.flameshot = {
      enable = true;

      settings = {
        General = {
          savePath = "pic/scr/";
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
