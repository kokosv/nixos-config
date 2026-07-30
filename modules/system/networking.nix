{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.networking;
in
{
  config = lib.mkIf cfg.enable {
    networking = {
      enableIPv6 = true;
      nameservers = [
        "86.54.11.100"
        "86.54.11.200"
      ];
      networkmanager = {
        enable = true;
        dns = "systemd-resolved";
        wifi = {
          backend = "iwd";
          powersave = false;
        };
      };

      # Enables wireless support via wpa_supplicant.
      # networking.wireless.enable = true;

      # Configure network proxy if necessary
      # networking.proxy.default = "http://user:password@proxy:port/";
      # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

      # Open ports in the firewall.
      # networking.firewall.allowedTCPPorts = [ ... ];
      # networking.firewall.allowedUDPPorts = [ ... ];
      # Or disable the firewall altogether.
      # networking.firewall.enable = false;
    };

    services.resolved = {
      enable = true;
      dnssec = "allow-downgrade";
      domains = [ "~." ];
      fallbackDns = [
        "86.54.11.100"
        "86.54.11.200"
      ];
    };
  };
}
