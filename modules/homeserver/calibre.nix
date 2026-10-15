{ lib, ... }: {
  options.homeserver.calibre = lib.mkOption { type = lib.types.deferredModule; };

  config.homeserver.calibre = { ... }: {
    systemd.tmpfiles.rules = [
      "d /d06-knigi 0750 calibre-server calibre-server -"
    ];

    services.calibre-server = {
      enable = true;
      libraries = [ "/d06-knigi" ];
      host = "0.0.0.0"; # must be reachable from the VPS over tailscale
      port = 8081;
      auth.enable = true;
      auth.mode = "auto";
      # Created once via: calibre-server --userdb=/var/lib/calibre-server/users.sqlite
      # --manage-users -- add <user> <password>  (see notes/homelab-architecture.md)
      auth.userDb = "/var/lib/calibre-server/users.sqlite";
    };
  };
}
