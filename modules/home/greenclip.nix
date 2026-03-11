{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.greenclip;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ greenclip ];

    service.greenclip = {
      enable = true;
    };

  };
}
