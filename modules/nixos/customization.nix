{ lib, pkgs, ... }: {
  options.nixos.customization = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.customization = {
    time.timeZone = "Europe/Bucharest";

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

    console = {
      keyMap = "dvorak";
      font = "DepartureMono Nerd Font";
    };

    xdg.portal = {
      enable = true;
      config.common.default = "gtk";
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };

    fonts.packages = with pkgs; [ nerd-fonts.departure-mono ];
  };
}
