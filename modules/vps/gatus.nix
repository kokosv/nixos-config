{ lib, ... }: {
  options.vps.gatus = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.gatus = { ... }: {
    services.gatus = {
      enable = true;
      settings = {
        web.port = 8081;
        endpoints = [

          # ── VPS ────────────────────────────────────────────────────────────
          {
            name = "Headscale";
            group = "VPS";
            url = "https://headscale.vafla.eu/health";
            interval = "5m";
            # Shared *.vafla.eu wildcard cert — only checked here, redundant elsewhere.
            conditions = [
              "[STATUS] == 200"
              "[CERTIFICATE_EXPIRATION] > 336h"
            ];
          }
          {
            name = "Headplane";
            group = "VPS";
            # Direct check — bypasses Authentik (which only ever gates the request
            # before the backend, so a public-hostname check never reflects real health).
            # Runs on the VPS itself, not homeserver.
            url = "http://127.0.0.1:3000/admin"; # dashboard lives at /admin, not /
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          # ── MC ─────────────────────────────────────────────────────────────
          {
            name = "Minecraft server";
            group = "MC";
            enabled = false;
            url = "tcp://vafla.eu:25565";
            interval = "5m";
            conditions = [ "[CONNECTED] == true" ];
          }
          {
            name = "mc.vafla.eu";
            group = "MC";
            enabled = false;
            url = "https://mc.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "map.mc.vafla.eu";
            group = "MC";
            enabled = false;
            url = "https://map.mc.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }

          # ── Home Server ─────────────────────────────────────────────────────
          {
            name = "Landing page";
            group = "Home Server";
            enabled = false;
            url = "https://vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Proxmox";
            group = "Home Server";
            url = "https://proxmox.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {

            name = "Homarr";
            group = "Home Server";
            enabled = false;
            # Direct backend check over tailnet — bypasses Authentik, which only ever
            # gates the request before it reaches the backend. Port TBD at deploy time.
            url = "http://100.64.0.5:9999";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Microbin";
            group = "Home Server";
            enabled = false;
            url = "http://100.64.0.5:9999"; # direct backend check — port TBD at deploy time
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Forgejo";
            group = "Home Server";
            enabled = false;
            url = "http://100.64.0.5:9999"; # direct backend check — port TBD at deploy time
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Owncast";
            group = "Home Server";
            enabled = false;
            url = "http://100.64.0.5:9999"; # direct backend check — port TBD at deploy time
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Cryptpad";
            group = "Home Server";
            enabled = false;
            url = "http://100.64.0.5:9999"; # direct backend check — port TBD at deploy time
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Peertube";
            group = "Home Server";
            enabled = false;
            url = "http://100.64.0.5:9999"; # direct backend check — port TBD at deploy time
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Immich";
            group = "Home Server";
            enabled = false;
            url = "http://100.64.0.5:9999"; # direct backend check — port TBD at deploy time
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Jellyfin";
            group = "Home Server";
            enabled = false;
            url = "http://100.64.0.5:9999"; # direct backend check — port TBD at deploy time
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Calibre";
            group = "Home Server";
            enabled = false;
            url = "http://100.64.0.5:9999"; # direct backend check — port TBD at deploy time
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Feishin";
            group = "Home Server";
            enabled = false;
            # Backend is actually Navidrome (Feishin is just a client UI) — port TBD at deploy time
            url = "http://100.64.0.5:9999";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Matrix";
            group = "Home Server";
            enabled = false;
            url = "http://100.64.0.5:9999"; # direct backend check — port TBD at deploy time
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Technitium";
            group = "Home Server";
            url = "http://100.64.0.5:5380"; # direct backend check, bypasses Authentik
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Authentik";
            group = "Home Server";
            url = "https://auth.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "rechnik.vafla.eu";
            group = "Home Server";
            enabled = false;
            url = "https://rechnik.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }

        ];
      };
    };

    # nginx vhost lives in anubis.nix — all public-tier vhosts are owned there
  };
}
