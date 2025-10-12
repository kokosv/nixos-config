{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.clipse;
in {
  config = lib.mkIf cfg.enable {
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
