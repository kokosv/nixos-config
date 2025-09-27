{ config, pkgs, lib, ... }:

let
  cfg = config.modules.i3;
  mod = "Mod4";
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ i3 ];
    
    services.xserver.windowManager.i3.enable = true;
  };
}
