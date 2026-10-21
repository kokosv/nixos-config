{ lib, ... }: {
  options.vps.gatus = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.gatus = { config, ... }: {
    age.secrets.nazhivo-gatus-auth = {
      file = ../../secrets/nazhivo-gatus-auth.age;
      owner = "root"; # read by systemd (EnvironmentFile=) before gatus's DynamicUser exec, not by gatus itself
    };

    services.gatus = {
      enable = true;
      environmentFile = config.age.secrets.nazhivo-gatus-auth.path;
      settings = {
        web.port = 8081;
        endpoints = [

          # ── minecraft ──────────────────────────────────────────────────────
          {
            name = "Minecraft server";
            group = "minecraft";
            enabled = false;
            url = "tcp://vafla.eu:25565";
            interval = "5m";
            conditions = [ "[CONNECTED] == true" ];
          }
          {
            name = "mc.vafla.eu";
            group = "minecraft";
            enabled = false;
            url = "https://mc.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "map.mc.vafla.eu";
            group = "minecraft";
            enabled = false;
            url = "https://map.mc.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }

          # ── public ─────────────────────────────────────────────────────────
          {
            name = "Headscale";
            group = "public";
            url = "https://headscale.vafla.eu/health";
            interval = "5m";
            # Shared *.vafla.eu wildcard cert — only checked here, redundant elsewhere.
            conditions = [
              "[STATUS] == 200"
              "[CERTIFICATE_EXPIRATION] > 336h"
            ];
          }
          {
            name = "Landing page";
            group = "public";
            enabled = false;
            url = "https://vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Enclosed";
            group = "public";
            enabled = true;
            url = "https://taina.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Forgejo";
            group = "public";
            enabled = false;
            url = "https://git.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Owncast";
            group = "public";
            enabled = true;
            url = "https://nazhivo.vafla.eu";
            interval = "5m";
            # vhost is behind nginx auth_basic — credentials needed or every check 401s.
            headers.Authorization = "\${NAZHIVO_AUTH}";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Cryptpad";
            group = "public";
            enabled = true;
            url = "https://dok.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Peertube";
            group = "public";
            enabled = false;
            url = "https://tube.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Immich";
            group = "public";
            enabled = false;
            url = "https://media.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Jellyfin";
            group = "public";
            enabled = false;
            url = "https://tv.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "rechnik.vafla.eu";
            group = "public";
            enabled = false;
            url = "https://rechnik.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }

          # ── private ────────────────────────────────────────────────────────
          {
            name = "Headplane";
            group = "private";
            url = "https://headplane.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Proxmox";
            group = "private";
            url = "https://proxmox.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Homarr";
            group = "private";
            enabled = false;
            # Port TBD at deploy time.
            url = "http://100.64.0.5:9999";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Calibre";
            group = "private";
            enabled = true;
            url = "https://knigi.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Navidrome";
            group = "private";
            enabled = false;
            #  port TBD at deploy time
            url = "http://100.64.0.5:9999";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "Technitium";
            group = "private";
            url = "https://dns.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "qBittorrent";
            group = "private";
            enabled = true;
            url = "https://torrent.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
          {
            name = "4get";
            group = "private";
            enabled = true;
            url = "https://tursi.vafla.eu";
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }

        ];
      };
    };

    # nginx vhost lives in anubis.nix — all public-tier vhosts are owned there
  };
}
