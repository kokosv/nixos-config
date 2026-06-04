{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.lazygit;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ lazygit ];

    programs.lazygit = {
      enable = true;
      enableZshIntegration = true;
    };

  };
}
