{ config, pkgs, lib, ... }:

let
  cfg = config.modules.dm;
in {
#  options.modules.tuigreet.enable = lib.mkEnableOption "tuigreet login manager";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ greetd.tuigreet ];

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet";
          args = [
            "--time"
            "--asterisks"
            "--user-menu"
            "--cmd" "i3"
          ];
        };
      };
    };

#   environment.etc."greetd/environments".text = ''
#      i3
#      bash
#    '';

  };
}
