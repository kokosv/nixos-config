{ lib, ... }: {
  options.nixos.environmentalVariables = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.environmentalVariables = {
    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      LIBVA_DRIVER_NAME = "iHD";
      MOZ_X11_EGL = "1";
    };
  };
}
