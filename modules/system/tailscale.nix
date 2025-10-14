{ config, pkgs, lib, ... }:

let
  cfg = config.modules.tailscale;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ tailscale ];
    
     services.tailscale.enable = true;

     networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };

  };
}
