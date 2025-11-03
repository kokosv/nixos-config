{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.direnv;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ direnv nix-direnv ];

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableBashIntegration = true;
    };
  };
}
