{ config, pkgs, lib, ... }:

let
  super = "Mod4";
  alt_L = "Mod1";
  alt_R = "Mod3";
  enter = "Return";
in {
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      # execute at startup
      startup = [
        {
          command = "${pkgs.systemd}/bin/systemctl --user start i3-session.service &";
          always = true;
	}
        { 
          command = "i3-msg workspace 1";
          always = true; 
        }
        
      ];

      fonts = {
        names = [ "DepartureMono Nerd Font" ];
        size = 11.0;
      };

      terminal = "kitty";

      bars = [{
        position = "top";
        statusCommand = "${pkgs.i3blocks}/bin/i3blocks";
        fonts = {
          names = [ "DepartureMono Nerd Font" ];
          size = 11.0;
        };
      }];

      keybindings = lib.mkOptionDefault {

	"${alt_L}+h" = "focus left";
        "${alt_L}+j" = "focus down";
        "${alt_L}+k" = "focus up";
        "${alt_L}+l" = "focus right";

        "${alt_L}+Shift+h" = "move left";
        "${alt_L}+Shift+j" = "move down";
        "${alt_L}+Shift+k" = "move up";
        "${alt_L}+Shift+l" = "move right";

	# fkeys
        # f8
        "XF86WLAN" = "exec kitty -e nmtui";
 
        "${super}+k" = "kill";

	# copy / paste
	#"${alt_L}+c" = "exec xclip -selection clipboard";
	#"${alt_L}+p" = "exec xclip -selection clipboard -o";

	# open programs
        "${alt_L}+${enter}" = "exec kitty";
	#"${alt_R}+${enter}" = "exec firefox";
	#"${alt_R}+c" = "exec kitty -e clipse";
        #"${alt_R}+d" = "exec rofi -show drun";
 
 	"${alt_L}+b" = "exec kitty --class clipse --title clipse -e clipse";
        "${alt_L}+d" = "exec rofi -show drun";
           
      };

      window.commands = [
        {
          command = "floating enable, resize set 500 500, move position center";
	  criteria = { class = "^clipse$"; };
	}
        {
          command = "floating enable, resize set 500 500, move position center";
	  criteria = { title = "^clipse$"; };
	}

      ];

    };
  };
}
