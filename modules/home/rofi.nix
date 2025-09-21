{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.rofi;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ rofi ];

  };
}
