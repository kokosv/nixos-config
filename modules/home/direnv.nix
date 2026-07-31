{ lib, ... }: {
  options.homeManager.direnv = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.direnv = { pkgs, ... }: {
    home.packages = with pkgs; [
      direnv
      nix-direnv
    ];

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
}
