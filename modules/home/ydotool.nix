{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.ydotool;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ ydotool ]; 
    
    systemd.user.services.ydotoold = {
      Unit = {
        Description = "ydotool daemon";
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.ydotool}/bin/ydotoold --socket-path /tmp/ydotools.sock";
        Restart = "on-failure";
      };
    };

    home.sessionVariables = {
      YDOTOOL_SOCKET = "/tmp/ydotools.sock";
    };

  };
}
