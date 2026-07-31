{ lib, ... }: {
  options.homeManager.kitty = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.kitty = { pkgs, ... }: {
    home.packages = with pkgs; [ kitty ];

    programs.kitty = {
      enable = true;
      settings = {
        confirm_os_window_close = 0;
        font_size = 13;
        font_family = "DepartureMono Nerd Font";
        allow_hyperlinks = true;
      };
      keybindings = {
        "ctrl+plus" = "change_font_size all +1.0";
        "ctrl+minus" = "change_font_size all -1.0";
      };
    };
  };
}
