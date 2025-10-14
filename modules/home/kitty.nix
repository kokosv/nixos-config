{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.kitty;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ kitty ];

    programs.kitty = {
      enable = true;

      settings = {
        confirm_os_window_close = 0;
	font_size = 13;
        font_family = "DepartureMono Nerd Font";
        background_opacity = "0.65";
        allow_hyperlinks = true;
#       clipboard_control = "write-clipboard read-clipboard write-primary read-primary";
      };
      
#     themeFile = "GruvboxMaterialDarkHard"; 
      
      keybindings = {
        "ctrl+plus" = "change_font_size all +1.0";
        "ctrl+minus" = "change_font_size all -1.0";
#	"alt+c" = "copy_or_interrupt";
#	"alt+v" = "paste";
      };

    }; 
  };
}
