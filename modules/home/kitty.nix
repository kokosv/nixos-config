{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.kitty;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ kitty ];

    programs.kitty = {
      enable = true;
      settings = {
        confirm_os_window_close = 0; # No confirmation prompt
	font_size = 11;
        font_family = "JetBrainsMono Nerd Font Mono";
        bold_font = "JetBrainsMono Nerd Font Mono Bold";
      };
      
      #themeFile = "path/theme.conf";

      keybindings = {
        "ctrl+shift+plus" = "change_font_size all +1.0";
        "ctrl+shift+minus" = "change_font_size all -1.0";
      };
    }; 
  };
}
