{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.fzf;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ fzf ];

    programs.fzf = {
      enable = true;
      enableBashIntegration = true;

      defaultOptions = [
        "--style minimal"
        "--height 40%"
        "--layout reverse"
        "--bind ctrl-j:down"
        "--bind ctrl-k:up"
        #"--preview 'cat {}'"
      ];
    };

  };
}
