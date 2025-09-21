{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.wget;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ wget ];
  };
}
