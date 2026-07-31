{ lib, ... }: {
  options.homeManager.lazygit = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.lazygit = { pkgs, ... }: {
    home.packages = with pkgs; [ lazygit ];

    programs.lazygit = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
