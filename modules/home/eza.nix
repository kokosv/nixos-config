{ lib, ... }: {
  options.homeManager.eza = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.eza = { pkgs, ... }: {
    home.packages = with pkgs; [ eza ];

    programs.eza = {
      enable = true;
      enableBashIntegration = false;
      git = true;
      icons = "always";
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };
  };
}
