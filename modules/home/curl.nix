{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.curl;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ curl ];
  };
}
