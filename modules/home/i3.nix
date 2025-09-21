{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.i3;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ i3 ];
    
    xsession.windowManager.i3 = {
      enable = true;
      config = {
        modifier = "Mod4";
        bars = [];
        keybindings = lib.mkOptionDefault {
          "Mod4+Return" = "exec kitty";
          "Mod4+d" = "exec rofi -show drun";
	  "Mod4+Shift+q" = "kill";
        };
      };
    };
  };
}
