{ config, pkgs, lib, ... }:

let
  cfg = config.modules.moonlight;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ moonlight-qt ];
    
    networking.firewall.allowedTCPPorts = [ 47984 47989 48010 ];
    networking.firewall.allowedUDPPorts = [ 47998 47999 48000 48002 48010 ];

    hardware.opengl = {
      enable = true;
   };

  };
}
