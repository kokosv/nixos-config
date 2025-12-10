{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.git;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ git ];
    
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "kokosv";
	  email = "kaloyansv@gmail.com";
	};
	init.defaultBranch = "main";
      };

#      userName = "kokosv";
#      userEmail = "kaloyansv@gmail.com";
#      extraConfig = {
#        init.defaultBranch = "main";
#      };
    };
  };
}
