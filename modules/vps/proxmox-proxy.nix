{ lib, ... }: {
  options.vps.proxmoxProxy = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.proxmoxProxy = { ... }: {
    services.nginx.virtualHosts."proxmox.vafla.eu" = {
      listenAddresses = [ "100.64.0.1" ];
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "https://100.64.0.4:8006";
        proxyWebsockets = true; # required for the Proxmox console
        extraConfig = ''
          proxy_ssl_verify off; # Proxmox serves its own self-signed cert
        '';
      };
    };
  };
}
