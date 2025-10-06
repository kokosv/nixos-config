{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.neovim;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ neovim ];

  };
}
