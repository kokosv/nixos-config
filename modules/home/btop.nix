{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.btop;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ btop ];

    programs.btop = {
      enable = true;
      settings = {
        color_theme = "TTY";
        theme_background = false;
        vim_keys = true;
        rounded_corners = false;
      };
    };
  };
}
