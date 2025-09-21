{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.eza;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ eza ]; 
    
    # Optional: make eza the default ls command
    programs.eza = {
      enable = true;
      #enableAliases = true; # Adds aliases like ls -> eza
    };
  };
}
