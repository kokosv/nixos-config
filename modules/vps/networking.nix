{ lib, ... }: {
  options.vps.networking = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.networking = {
    # Headscale.vafla.eu resolves to the public IP which the VPS can't hairpin back to.
    # Point it to localhost so tailscale up connects via nginx on 127.0.0.1:443 instead.
    networking.hosts."127.0.0.1" = [ "headscale.vafla.eu" ];

    networking.nameservers = [
      "86.54.11.100"
      "86.54.11.200"
    ];

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
        25565
      ]; # 25565 = Minecraft
      allowedUDPPorts = [
        3478
        25565
      ]; # 3478 = STUN for DERP, 25565 = Minecraft
      trustedInterfaces = [ "tailscale0" ];
      checkReversePath = "loose"; # required for tailscale
    };

    services.tailscale.enable = true;
  };
}
