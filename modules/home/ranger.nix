{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.ranger;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ ranger ];

  };
}
