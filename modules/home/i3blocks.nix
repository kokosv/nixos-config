{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.i3blocks;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ i3blocks ]; 

  };
}
