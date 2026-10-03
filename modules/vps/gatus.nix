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
            name = "Landing page";
            group = "VPS";
            enabled = false;
            url = "https://vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Headscale";
            group = "VPS";
            url = "https://headscale.vafla.eu/health";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Headplane";
            group = "VPS";
            enabled = false;
            url = "https://headplane.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
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
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "map.mc.vafla.eu";
            group = "MC";
            enabled = false;
            url = "https://map.mc.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }

          # ── Home Server ─────────────────────────────────────────────────────
          {
            name = "Homarr";
            group = "Home Server";
            enabled = false;
            url = "https://homarr.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Microbin";
            group = "Home Server";
            enabled = false;
            url = "https://share.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Forgejo";
            group = "Home Server";
            enabled = false;
            url = "https://git.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Owncast";
            group = "Home Server";
            enabled = false;
            url = "https://stream.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Cryptpad";
            group = "Home Server";
            enabled = false;
            url = "https://dok.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Peertube";
            group = "Home Server";
            enabled = false;
            url = "https://tube.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Immich";
            group = "Home Server";
            enabled = false;
            url = "https://media.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Jellyfin";
            group = "Home Server";
            enabled = false;
            url = "https://tv.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Calibre";
            group = "Home Server";
            enabled = false;
            url = "https://biblioteka.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Homelable";
            group = "Home Server";
            enabled = false;
            url = "https://chertezh.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Archivebox";
            group = "Home Server";
            enabled = false;
            url = "https://webarhiv.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Feishin";
            group = "Home Server";
            enabled = false;
            url = "https://muzika.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Matrix";
            group = "Home Server";
            enabled = false;
            url = "https://matrix.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "Technitium";
            group = "Home Server";
            enabled = false;
            url = "https://dns.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "radio-spektar.vafla.eu";
            group = "Home Server";
            enabled = false;
            url = "https://radio-spektar.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "recepti.vafla.eu";
            group = "Home Server";
            enabled = false;
            url = "https://recepti.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }
          {
            name = "rechnik.vafla.eu";
            group = "Home Server";
            enabled = false;
            url = "https://rechnik.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" "[CERTIFICATE_EXPIRATION] > 336h" ];
          }

        ];
      };
    };

    # nginx vhost lives in anubis.nix — all public-tier vhosts are owned there
  };
}
