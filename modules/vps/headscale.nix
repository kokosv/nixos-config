{ lib, ... }: {
  options.vps.headscale = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.headscale = { pkgs, inputs, ... }: {
    services.headscale = {
      enable = true;
      package = inputs.headscale.packages.${pkgs.system}.headscale;
      address = "0.0.0.0";
      port = 8080;
      settings = {
        server_url = "https://headscale.vafla.eu";
        dns = {
          base_domain = "tailnet.vafla.eu";
          # primary will be the home VM Technitium IP — fill in after home VM is up
          nameservers.global = [ "86.54.11.100" ]; # DNS4EU unfiltered fallback
        };
        derp.server = {
          enabled = true;
          region_id = 999;
          region_code = "home";
          region_name = "Home";
          stun_listen_addr = "0.0.0.0:3478";
        };
        derp.urls = []; # disable fallback to Tailscale's public DERP servers
      };
    };

    services.nginx.virtualHosts."headscale.vafla.eu" = {
      forceSSL = true;
      useACMEHost = "vafla.eu";
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };
    };
  };
}
