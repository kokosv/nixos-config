{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.apps;
in
{
  config = lib.mkIf cfg.enable {
    xdg.desktopEntries = {

      btop = {
        name = "btop";
        genericName = "System Monitor TUI";
        comment = "Resource monitor";
        exec = "kitty --class btop -e btop";
        terminal = false;
        categories = [
          "System"
          "Monitor"
        ];
      };

      ikhal = {
        name = "ikhal";
        genericName = "Kalendar TUI";
        comment = "Interactive khal calendar";
        exec = "kitty --class ikhal -e ikhal";
        terminal = false;
        categories = [
          "Office"
          "Calendar"
        ];
      };

      nmtui = {
        name = "nmtui";
        genericName = "Network TUI";
        comment = "Terminal network manager";
        exec = "kitty --class nmtui -e nmtui";
        terminal = false;
        categories = [
          "System"
          "Network"
        ];
      };

      bluetui = {
        name = "bluetui";
        genericName = "Bluetooth TUI";
        comment = "Terminal Bluetooth manager";
        exec = "kitty --class bluetui -e bluetui";
        terminal = false;
        categories = [
          "System"
          "Network"
        ];
      };
    };
  };
}
