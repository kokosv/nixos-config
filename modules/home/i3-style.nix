{ config, pkgs, lib, ... }:

let
  super = "Mod4";
  alt_L = "Mod1";
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
 #       { 
 #         command = " ";
 #         always = true; 
 #       }
        
      ];

      defaultWorkspace = "workspace number 1";

      fonts = {
        names = [ "DepartureMono Nerd Font" ];
        size = 13.0;
      };
	
      focus.followMouse = false;

      terminal = "kitty";
      menu = "rofi";

      bars = [{
        position = "top";
        statusCommand = "${pkgs.i3blocks}/bin/i3blocks";
        fonts = {
          names = [ "DepartureMono Nerd Font" ];
          size = 13.0;
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
#	"XF86AudioMute" = "";                    # F1 (Deafen sound)
#	"XF86AudioLowerVolume" = "";             # F2 (Volume down)
#	"XF86AudioRaiseVolume" = "";             # F3 (Volume up)
#	"XF86AudioMicMute" = "";                 # F4 (Mute mic)
#	"XF86MonBrightnessDown" = "";            # F5 (Brightness down)
#	"XF86MonBrightnessUp" = "";              # F6 (Brightness up)
#	"XF86Display" = "";                      # F7 (Second monitor mode)
	"XF86WLAN" = "exec kitty --class nmtui -e nmtui";  # F8 (Network)
#	"XF86Tools" = "";                        # F9 (Gear)
	"XF86Bluetooth" = "exec kitty --class bluetui -e bluetui";  # F10 (Bluetooth)
#	"XF86Keyboard" = "";                     # F11 (Keyboard)
#	"XF86Favorites" = "";                    # F12 (Star)

        "${super}+k" = "kill";

	# open programs
        "${alt_L}+${enter}" = "exec kitty";
	"${alt_L}+Shift+${enter}" = "exec firefox";
 	"${alt_L}+Shift+c" = "exec kitty --class clipse -e clipse";
        "${alt_L}+d" = "exec rofi -show drun";
        "${alt_L}+t" = "exec kitty --class btop -e btop";
	"${alt_L}+i" = "exec kitty --class ikhal -e ikhal";

      };

      window.commands = [
        {
          command = "floating enable, resize set 700 500, move position center";
 	  criteria = { class = "^clipse$"; };
	}
        {
          command = "floating enable, resize set 700 700, move position center";
 	  criteria = { class = "^nmtui$"; };
	}
        {
          command = "floating enable, resize set 1920 1080, move position center";
 	  criteria = { class = "^bluetui$"; };
	}
        {
          command = "floating enable, resize set 1200 800, move position center";
 	  criteria = { class = "^btop$"; };
	}
        {
          command = "floating enable, resize set 700 500, move position center";
 	  criteria = { class = "^ikhal$"; };
	}

      ];

    };

    extraConfig = ''

      hide_edge_borders smart_no_gaps

      default_border pixel 0
      default_floating_border pixel 1

      client.focused          #FFFFFF #000000 #FFFFFF #000000 #FFFFFF
      client.unfocused        #777777 #000000 #777777 #000000 #777777

      for_window [class="firefox"] border pixel 0
      for_window [class="kitty"] border pixel 1



    '';

#      for_window [class="kitty"] opacity 0.7
#      for_window [class="kitty" floating] opacity 1.0
  };
}
