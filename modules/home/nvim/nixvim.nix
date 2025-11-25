{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.nixvim;
in {
  config = lib.mkIf cfg.enable {
    # home.packages = with pkgs; [ neovim ];

  };
}
