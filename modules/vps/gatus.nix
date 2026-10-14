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
            url = "https://headplane.vafla.eu";
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
            # Port TBD at deploy time.
            url = "http://100.64.0.5:9999";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Enclosed";
            group = "Home Server";
            enabled = true;
            url = "https://taina.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Forgejo";
            group = "Home Server";
            enabled = false;
            url = "https://git.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Owncast";
            group = "Home Server";
            enabled = false;
            url = "https://nazhivo.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Cryptpad";
            group = "Home Server";
            enabled = true;
            url = "https://dok.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Peertube";
            group = "Home Server";
            enabled = false;
            url = "https://tube.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Immich";
            group = "Home Server";
            enabled = false;
            url = "https://media.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Jellyfin";
            group = "Home Server";
            enabled = false;
            url = "https://tv.vafla.eu";
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
            name = "Navidrome";
            group = "Home Server";
            enabled = false;
            #  port TBD at deploy time
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
            url = "https://dns.vafla.eu";
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
