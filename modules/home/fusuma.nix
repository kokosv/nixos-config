{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.fusuma;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ fusuma ]; 

    # after making changes 
    # restart the service
    # systemctl --user restart fusuma.service 

    services.fusuma = {
      enable = true;

      settings = {
        
        swipe = {
          "3" = {
            left.command = "${pkgs.i3}/bin/i3-msg 'workspace next'";
            right.command = "${pkgs.i3}/bin/i3-msg 'workspace prev'";
          };
        };
        
        pinch = {
          "2" = {
            "out".command = "${pkgs.xdotool}/bin/xdotool key ctrl+plus";
            "in".command = "${pkgs.xdotool}/bin/xdotool key ctrl+minus";
#	    "out".command = "${pkgs.ydotool}/bin/ydotool key 29:1 42:1 78:1 29:0 42:0 78:0"; # Ctrl+Shift+Plus
#            "in".command = "${pkgs.ydotool}/bin/ydotool key 29:1 42:1 74:1 29:0 42:0 74:0"; # Ctrl+Shift+Minus
          };
        };

        threshold = {
          swipe = 0.75;
          pinch = 0.75;
        };

        interval = {
          swipe = 0.5;
          pinch = 0.1;
        };

      };
    };
  };
}
