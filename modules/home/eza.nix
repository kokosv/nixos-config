{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.eza;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ eza ]; 
    
    programs.eza = {
      enable = true;
    };
  };
}
