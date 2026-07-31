{ lib, ... }: {
  options.homeManager.git = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.git = { pkgs, ... }: {
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
