{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.fzf;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ fzf ];

    # Optional: enable fuzzy finding for bash/zsh
    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
    };
  };
}
