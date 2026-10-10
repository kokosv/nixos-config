{ lib, ... }: {
  options.vps.mcProxy = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.mcProxy = {
    # TCP proxy for Minecraft server running on the home VM via Tailscale.
    # Fill in the home VM's tailscale IP once it is provisioned.
    services.nginx.streamConfig = ''
      server {
        listen 25565;
        listen [::]:25565;
        proxy_pass <home-vm-tailscale-ip>:25565;
      }
    '';
  };
}
