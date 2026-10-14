{ lib, ... }: {
  options.homeserver.owncast = lib.mkOption { type = lib.types.deferredModule; };

  config.homeserver.owncast = { ... }: {
    services.owncast = {
      enable = true;
      listen = "0.0.0.0"; # must be reachable from the VPS over tailscale
      port = 8080;
      rtmp-port = 1935; # broadcaster (OBS) pushes here directly over tailscale
    };
    # No hardware video encoding available: /dev/dri on this VM is bochs-drm
    # (QEMU's virtual framebuffer), not a real GPU — software x264 only.
    # Quality variants, directory/search-indexing/fediverse toggles, admin
    # password and stream key are DB-backed (no declarative config file in
    # this owncast version) — set once via the admin API/UI after first boot,
    # see notes/homelab-architecture.md.
  };
}
