{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.polybar;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ polybar ];
    
    services.polybar = {
      enable = true;
    };

  };
}
