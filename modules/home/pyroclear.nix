{ lib, ... }: {
  options.homeManager.pyroclear = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.pyroclear = { pkgs, inputs, ... }: {
    home.packages = [ inputs.pyroclear.packages.${pkgs.stdenv.hostPlatform.system}.default ];

    xdg.configFile."pyroclear/config.toml".text = ''
      [color]
      palette = "mono"

      [animation]
      fps             = 30
      wind            = 0
      height          = 2
      direction       = 1
      duration        = 1.5
      flames_duration = 0.3
    '';
  };
}
