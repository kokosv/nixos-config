{ config, pkgs, lib, ... }:

let
  cfg = config.modules.ly;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ ly ];

    services.displayManager.ly = {
      enable = true;
    };
  };
}
