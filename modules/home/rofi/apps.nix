{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.apps;
in {
  config = lib.mkIf cfg.enable {
    xdg.desktopEntries = {
      bluetui = {
        name = "bluetui";
        genericName = "Bluetooth TUI";
        comment = "Terminal Bluetooth manager";
        exec = "kitty --class bluetui -e bluetui";
        terminal = false;
        categories = [ "System" "Network" ];
      };
      
      nmtui = {
        name = "nmtui";
        genericName = "Network TUI";
        comment = "Terminal network manager";
        exec = "kitty --class nmtui -e nmtui";
        terminal = false;
        categories = [ "System" "Network" ];
      };
    };
  };
}
