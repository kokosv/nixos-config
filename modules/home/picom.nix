{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.picom;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ picom ];

    services.picom = {
      enable = true;
      
      settings = {

      };

    };
  };
}
