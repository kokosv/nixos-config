{ config, pkgs, lib, ... }:

let
  cfg = config.modules.dm;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ tuigreet ];

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = ''${pkgs.tuigreet}/bin/tuigreet --time --time-format "[w'%W]   [d'%j]   [%a]   [%Y/%m/%d]   [%H:%M:%S]   [%z]" --window-padding 2 --greeting '"An idiot admires complexity, a genius admires simplicity" - Terry Davis' --asterisks --remember --remember-user-session --xsessions "${config.services.displayManager.sessionData.desktops}/share/xsessions" --xsession-wrapper "startx /usr/bin/env" -d '';
        };
      };
    };
  };
}
