{ lib, ... }: {
  options.homeManager.btop = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.btop = { pkgs, ... }: {
    home.packages = with pkgs; [ btop ];

    programs.btop = {
      enable = true;
      settings = {
        color_theme = "TTY";
        theme_background = true;
        vim_keys = true;
        rounded_corners = false;
      };
    };
  };
}
