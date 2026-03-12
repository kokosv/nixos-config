{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.greenclip;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ haskellPackages.greenclip ];

    services.greenclip = {
      enable = true;
    };

  };
}
