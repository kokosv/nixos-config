{ lib, ... }: {
  options.homeManager.picom = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.picom = { pkgs, ... }: {
    home.packages = with pkgs; [ picom ];

    services.picom = {
      enable = true;
      settings = {
        vsync = true;
        backend = "glx";
        detect-transient = true;
        detect-client-leader = true;
        mark-wmwin-focused = true;
        mark-ovredir-focused = true;
        detect-client-opacity = true;
        exclude = [
          "class_g = 'jetbrains-studio' && (window_type = 'menu' || window_type = 'dropdown_menu' || window_type = 'popup_menu')"
          "class_g = 'jetbrains-idea' && (window_type = 'menu' || window_type = 'dropdown_menu' || window_type = 'popup_menu')"
        ];
      };
      opacityRules = [
        "100:class_g = 'kitty'"
        "100:I3_FLOATING_WINDOW@:32c = 1"
      ];
    };
  };
}
