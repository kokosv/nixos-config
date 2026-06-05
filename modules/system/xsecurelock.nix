{ config, pkgs, lib, ... }:

let
  cfg = config.modules.xsecurelock;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ 
      xsecurelock 
      xss-lock 
    ];

    programs.xss-lock = {
      enable = true;
      lockerCommand = "${pkgs.xsecurelock}/bin/xsecurelock";
    };
    
  };
}
