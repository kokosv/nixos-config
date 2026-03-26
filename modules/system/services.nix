{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.services;
in
{
  config = lib.mkIf cfg.enable {

    systemd.services = {

    };

  };
}
