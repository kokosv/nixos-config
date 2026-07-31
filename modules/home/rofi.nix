{ lib, ... }: {
  options.homeManager.rofi = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.rofi = { pkgs, config, ... }:
    let
      inherit (config.lib.formats.rasi) mkLiteral;
    in
    {
      home.packages = with pkgs; [
        rofi
        rofi-pulse-select # sink/source
        rofi-power-menu
        rofi-bluetooth
        rofi-network-manager
        rofi-systemd
      ];

      programs.rofi = {
        enable = true;

        # must have font size to pick up the font
        font = "DepartureMono Nerd Font 13";
        # theme = "dmenu";
        terminal = "${pkgs.kitty}/bin/kitty";

        modes = [
          "drun"
          #        "run"
          #        "ssh"
          #        "combi"
          #        "windowcd"
          #        "keys"
          #        "filebrowser"
          #        "recursivebrowser"
        ];

        # simple white border, white text, black background
        theme = {
          "*" = {
            background-color = mkLiteral "#000000";
            foreground = mkLiteral "#ffffff";
            border-color = mkLiteral "#ffffff";
          };
          # argument parsing for [ margin / padding / border ]
          # all
          # top&bottom left&right
          # top left&right bottom
          # top right bottom left

          "#window" = {
            background-color = mkLiteral "@background-color";
            border = 1;
            width = mkLiteral "20%";
            padding = mkLiteral "16px";
          };

          "#inputbar" = {
            background-color = mkLiteral "@background-color";
            border = mkLiteral "0px solid 0px solid 1px solid 0px solid";
            border-color = mkLiteral "@border-color";
            margin = mkLiteral "0px 0px 10px 0px";
          };

          "#element" = {
            text-color = mkLiteral "@foreground";
            background-color = mkLiteral "@background-color";
          };

          "#entry" = {
            text-color = mkLiteral "@foreground";
            background-color = mkLiteral "@background-color";
          };

          "#prompt" = {
            text-color = mkLiteral "@foreground";
            background-color = mkLiteral "@background-color";
          };

          # invert colours when selected
          "#element selected" = {
            text-color = mkLiteral "#000000";
            background-color = mkLiteral "#FFFFFF";
          };

          "#element-text" = {
            text-color = mkLiteral "inherit";
            background-color = mkLiteral "inherit";
          };
        };
      };

      xdg.desktopEntries = {
        btop = {
          name = "btop";
          genericName = "System Monitor TUI";
          comment = "Resource monitor";
          exec = "kitty --class btop -e btop";
          terminal = false;
          categories = [ "System" "Monitor" ];
        };

        ikhal = {
          name = "ikhal";
          genericName = "Kalendar TUI";
          comment = "Interactive khal calendar";
          exec = "kitty --class ikhal -e ikhal";
          terminal = false;
          categories = [ "Office" "Calendar" ];
        };

        nmtui = {
          name = "nmtui";
          genericName = "Network TUI";
          comment = "Terminal network manager";
          exec = "kitty --class nmtui -e nmtui";
          terminal = false;
          categories = [ "System" "Network" ];
        };

        bluetui = {
          name = "bluetui";
          genericName = "Bluetooth TUI";
          comment = "Terminal Bluetooth manager";
          exec = "kitty --class bluetui -e bluetui";
          terminal = false;
          categories = [ "System" "Network" ];
        };
      };
    };
}
