{ config, pkgs, lib, ... }:

let
  mod = "Mod4";
in {
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      fonts = {
        names = [ "departure-mono" ];
        size = 11.0;
      };

      bars = [{
        position = "top";
        statusCommand = "${pkgs.i3blocks}/bin/i3blocks";
      }];

      keybindings = lib.mkOptionDefault {
        "${mod}+Return" = "exec kitty";
        "${mod}+d" = "exec rofi -show drun";
        "${mod}+Shift+q" = "kill";

        "${mod}+h" = "focus left";
        "${mod}+t" = "focus down";
        "${mod}+n" = "focus up";
        "${mod}+semicolon" = "focus right";

        "${mod}+Shift+h" = "move left";
        "${mod}+Shift+t" = "move down";
        "${mod}+Shift+n" = "move up";
        "${mod}+Shift+semicolon" = "move right";
      };
    };
  };
}
