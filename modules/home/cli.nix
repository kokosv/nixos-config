{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.cli;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ 
      curl
      wget
      ranger
      xclip
    ];
  };
}
