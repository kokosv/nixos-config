{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.rofi;
  inherit (config.lib.formats.rasi) mkLiteral;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ rofi ];

    programs.rofi = {
      enable = true;
      
      # must have font size to pick up the font
      font = "DepartureMono Nerd Font 13";
#      theme = "dmenu";
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
      theme = let 
        simpleTheme = {
          "*" = {
            background-color = mkLiteral "#000000";
            foreground = mkLiteral "#ffffff";
            border-color = mkLiteral "#ffffff";
          };

          "#window" = {
            background-color = mkLiteral "@background-color";
            border = 1;
            width = mkLiteral "20%";
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

          "#element selected" = {
            text-color = mkLiteral "#000000";
            background-color = mkLiteral "#FFFFFF";
          };

          "#element-text" = {
            text-color = mkLiteral "inherit";
            background-color = mkLiteral "inherit";
          };
        };
      in simpleTheme;
    };
  };
}

