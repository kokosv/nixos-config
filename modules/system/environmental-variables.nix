{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.environmental-variables;
in
{
  config = lib.mkIf cfg.enable {

    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

  };
}
