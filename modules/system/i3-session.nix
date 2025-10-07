{ config, pkgs, lib, ... }:

let
  cfg = config.modules.i3-session;
in {
  config = lib.mkIf cfg.enable {
    
#    systemd.user.targets.i3-session = {
#      Description = "i3wm session";
#      BindsTo = [ "graphical-session.target" ];
#      Before = [ "graphical-session.target" ];
#      After = [ "graphical-session-pre.target" ];
#      Requires = [ "graphical-session-pre.target" ];
#    }; 
       
  };
}
