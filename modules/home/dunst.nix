{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.dunst;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ dunst ];

    services.dunst = {
      enable = true;
    
    };
  };
}
