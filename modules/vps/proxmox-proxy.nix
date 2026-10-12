{ lib, ... }: {
  options.vps.proxmoxProxy = lib.mkOption { type = lib.types.deferredModule; };

  # Tier 1 — tailnet-only, but an explicit exception: no Authentik wrapper.
  # Proxmox has its own login/auth; gating it behind Authentik too was deemed
  # unnecessary friction for a single-admin box.
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
