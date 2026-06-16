{
  config,
  pkgs,
  lib,
  ...
}:

let
  super = "Mod4";
  alt_L = "Mod1";
  enter = "Return";
in
{
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
          command = "exec --no-startup-id greenclip daemon";
          always = true;
        }
        #       {
        #         command = " ";
        #         always = true;
        #       }

      ];

      defaultWorkspace = "workspace number 1";

      workspaceAutoBackAndForth = true;

      fonts = {
        names = [ "DepartureMono Nerd Font" ];
        size = 13.0;
      };

      focus.followMouse = false;

      terminal = "kitty";
      menu = "rofi";

      bars = [ ]; # disable i3bar

      #      bars = [{
      #        position = "top";
      #        statusCommand = "${pkgs.i3blocks}/bin/i3blocks";

      #	fonts = {
      #          names = [ "DepartureMono Nerd Font" ];
      #          size = 13.0;
      #        };

      #        colors = {
      #          background = "#000000";
      #          separator = "#9A9996";

      #          focusedWorkspace = {
      #            background = "#000000";
      #            border = "#ffffff";
      #            text = "#ffffff";
      #          };
      #          inactiveWorkspace = {
      #            background = "#000000";
      #            border = "#9A9996";
      #            text = "#9A9996";
      #          };
      #          urgentWorkspace = {
      #            background = "#000000";
      #            border = "#ff0000";
      #            text = "#ff0000";
      #          };

      #	};
      #      }];

      keybindings = lib.mkOptionDefault {

        "${alt_L}+h" = "focus left";
        "${alt_L}+j" = "focus down";
        "${alt_L}+k" = "focus up";
        "${alt_L}+l" = "focus right";

        "${alt_L}+Shift+h" = "move left";
        "${alt_L}+Shift+j" = "move down";
        "${alt_L}+Shift+k" = "move up";
        "${alt_L}+Shift+l" = "move right";

        # fkeys - Thinkpad T480 ANSII keyboard layout
        "XF86AudioMute" = "exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; # F1 (Deafen sound)
        "XF86AudioLowerVolume" = "exec --no-startup-id wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; # F2 (Volume down)
        "XF86AudioRaiseVolume" = "exec --no-startup-id wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"; # F3 (Volume up)
        "XF86AudioMicMute" = "exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; # F4 (Mute mic)
        "XF86MonBrightnessDown" = "exec brightnessctl set 10%-"; # F5 (Brightness down)
        "XF86MonBrightnessUp" = "exec brightnessctl set 10%+"; # F6 (Brightness up)
        "XF86Display" = "exec --no-startup-id polybar-msg cmd toggle"; # F7 (Second monitor mode) - show/hide polybar
        "XF86WLAN" = "exec --no-startup-id rofi-network-manager"; # F8 (Network)
        "XF86Tools" = "exec --no-startup-id rofi-systemd"; # F9 (Gear)
        "XF86Bluetooth" = "exec --no-startup-id rofi-bluetooth"; # F10 (Bluetooth)
        # "XF86Keyboard" = "exec --no-startup-id polybar-msg cmd toggle"; # F11 (Keyboard)
        "XF86Favorites" = "exec --no-startup-id rofi -show p -modi p:rofi-power-menu --symbols --text"; # F12 (Star)

        # screenshot
        "Print" = "exec flameshot gui";

        # kill app
        "${super}+k" = "kill";

        # open programs
        "${alt_L}+${enter}" = "exec --no-startup-id kitty";
        "${alt_L}+Shift+${enter}" = "exec firefox";

        # use rofi instead
        # "${alt_L}+t" = "exec --no-startup-id kitty --class btop -e btop";
        # "${alt_L}+i" = "exec --no-startup-id kitty --class ikhal -e ikhal";

        "${alt_L}+d" = "exec --no-startup-id rofi -show drun";
        "${alt_L}+Shift+c" =
          "exec --no-startup-id rofi -modi 'clipboard:greenclip print ' -show clipboard -run-command '{cmd}'";

        #"${alt_L}+Shift+c" = "exec kitty --class clipse -e clipse"; # clipboard manager (better for wayland)

      };

      window.commands = [
        # {
        #   command = "floating enable, resize set 700 500, move position center";
        #   criteria = {
        #     class = "^clipse$";
        #   };
        # }

        {
          command = "floating enable, resize set 1600 1000, move position center";
          criteria = {
            class = "^btop$";
          };
        }
        {
          command = "floating enable, resize set 800 600, move position center";
          criteria = {
            class = "^ikhal$";
          };
        }

        {
          command = "floating enable, resize set 1600 1000, move position center";
          criteria = {
            class = "^nmtui$";
          };
        }
        {
          command = "floating enable, resize set 1000 800, move position center";
          criteria = {
            class = "^bluetui$";
          };
        }
        {
          command = "floating enable";
          criteria = {
            class = "^Yad$";
            title = "^yad-calendar$";
          };
        }
        {
          command = "floating enable, border none";
          criteria = {
            class = "^Yad$";
            title = "^System$";
          };
        }
      ];

    };

    extraConfig = ''

      hide_edge_borders smart_no_gaps

      default_border pixel 0
      default_floating_border none

      client.focused          #FFFFFF #000000 #FFFFFF #000000 #FFFFFF
      client.unfocused        #777777 #000000 #777777 #000000 #777777

      for_window [floating] border pixel 1
      for_window [class="kitty"] border pixel 1 

    '';
  };
}
