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
      LIBVA_DRIVER_NAME = "iHD";
      MOZ_X11_EGL = "1";
    };

  };
}
