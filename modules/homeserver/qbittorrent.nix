{ lib, ... }: {
  options.homeserver.qbittorrent = lib.mkOption { type = lib.types.deferredModule; };

  config.homeserver.qbittorrent = { ... }: {
    services.qbittorrent = {
      enable = true;
      webuiPort = 8090; # 8080 clashes with Owncast on this VM
      torrentingPort = 51413;
      openFirewall = false; # tailnet0 already trusted; no port-forward set up (no VPN, direct)
    };

    # Default WebUI login is admin/adminadmin — change it via the WebUI after first
    # deploy. Download categories (per-category save paths into the d0X-*/downloads
    # folders) are also set up there, not declaratively.
    users.users.qbittorrent.extraGroups = [ "media" ];
  };
}
