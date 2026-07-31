{ lib, ... }: {
  options.nixos.networking = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.networking = {
    networking = {
      enableIPv6 = true;
      nameservers = [ "86.54.11.100" "86.54.11.200" ];
      networkmanager = {
        enable = true;
        dns = "systemd-resolved";
        wifi = {
          backend = "iwd";
          powersave = false;
        };
      };
      # networking.wireless.enable = true;
      # networking.proxy.default = ...
      # networking.firewall.allowedTCPPorts = [ ... ];
      # networking.firewall.enable = false;
    };
    services.resolved = {
      enable = true;
      settings.Resolve = {
        DNSSEC = "allow-downgrade";
        Domains = [ "~." ];
        FallbackDNS = [ "86.54.11.100" "86.54.11.200" ];
      };
    };
  };
}
