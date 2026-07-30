{ config, pkgs, lib, ... }:

let
  cfg = config.modules.customization;
in {
  config = lib.mkIf cfg.enable {
    # Set your time zone.
    time.timeZone = "Europe/Bucharest";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "bg_BG.UTF-8";
      LC_IDENTIFICATION = "bg_BG.UTF-8";
      LC_MEASUREMENT = "bg_BG.UTF-8";
      LC_MONETARY = "bg_BG.UTF-8";
      LC_NAME = "bg_BG.UTF-8";
      LC_NUMERIC = "bg_BG.UTF-8";
      LC_PAPER = "bg_BG.UTF-8";
      LC_TELEPHONE = "bg_BG.UTF-8";
      LC_TIME = "bg_BG.UTF-8";
    };

    # Configure console defaults
    console = {
      keyMap = "dvorak";
      font = "DepartureMono Nerd Font";
    };

    xdg.portal = {
      enable = true;

      config = {
        common.default = "gtk";
      };

      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    # Fonts
    fonts.packages = with pkgs; [
      nerd-fonts.departure-mono
    ];
  };
}
