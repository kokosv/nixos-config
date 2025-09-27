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

        "${mod}+j" = "focus left";
        "${mod}+k" = "focus down";
        "${mod}+l" = "focus up";
        "${mod}+semicolon" = "focus right";

        "${mod}+Shift+j" = "move left";
        "${mod}+Shift+k" = "move down";
        "${mod}+Shift+l" = "move up";
        "${mod}+Shift+semicolon" = "move right";
      };
    };
  };
}
