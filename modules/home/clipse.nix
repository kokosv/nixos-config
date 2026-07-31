{ lib, ... }: {
  options.homeManager.clipse = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.clipse = { pkgs, ... }: {
    home.packages = with pkgs; [ clipse ];

    services.clipse = {
      enable = true;
      systemdTarget = "graphical-session.target";
      historySize = 32;
      allowDuplicates = false;
      imageDisplay.type = "kitty";
    };
  };
}
