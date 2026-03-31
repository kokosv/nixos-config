{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.gromit-mpx;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ gromit-mpx ];

    services.gromit-mpx = {
      enable = true;
    };

    # cheat sheet
    # F9:        toggle painting
    # SHIFT-F9:  clear screen
    # CTRL-F9:   toggle visibility
    # ALT-F9:    quit Gromit-MPX
    # F8:       undo last stroke
    # SHIFT-F8: redo last undone stroke
    # SHIFT+pointer - blue
    # SHIFT+pointer - yellow

    # does not work, dunno why

    #   opacity = 0.80;
    #   hotKey = "F12";
    #   undoKey = "Backspace";
    #
    #   tools = [
    #     {
    #       color = "red";
    #       device = "default";
    #       size = 5;
    #       type = "pen";
    #     }
    #     {
    #       device = "default";
    #       modifiers = [ "CONTROL" ];
    #       size = 20;
    #       type = "eraser";
    #     }
    #   ];
    # };

    # xdg.configFile."gromit-mpx/config".text = ''
    #   opacity = 0.80
    #   hotkey = F12
    #   undokey = Backspace
    #
    #   [tool:pen]
    #   color = red
    #   size = 5
    #   device = default
    #
    #   [tool:eraser]
    #   device = default
    #   modifiers = CONTROL
    #   size = 20
    # '';

  };
}
