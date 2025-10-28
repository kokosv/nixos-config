{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.others;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ 
      curl
      wget
      ranger
      xclip
      xdotool
      bluetui
      fd
      gcc
    ];
  };
}
