{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.picom;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ picom ];

    services.picom = {
      enable = true;
      
      settings = {
	vsync = true;
        backend = "glx";
        
	detect-transient = true;
        detect-client-leader = true;
        mark-wmwin-focused = true;
        mark-ovredir-focused = true;
        detect-client-opacity = true;
	
     };

     opacityRules = [
	"80:class_g = 'kitty'"  
        "100:I3_FLOATING_WINDOW@:32c = 1"	  
     ];
 
    };
  };
}
