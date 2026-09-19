{ lib, ... }: {
  options.nixos.tailscale = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.tailscale = { pkgs, config, ... }: {
    environment.systemPackages = with pkgs; [ tailscale ];
    services.tailscale.enable = true;
    networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };
}
