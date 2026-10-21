{ lib, ... }: {
  options.homeserver.fourget = lib.mkOption { type = lib.types.deferredModule; };

  config.homeserver.fourget = { config, pkgs, ... }:
  let
    src = pkgs.fetchgit {
      url = "https://git.lolcat.ca/lolcat/4get.git";
      rev = "ee0cecc32be2d16a61f9bbb8b991b2ad4fda1b26";
      hash = "sha256-OHB15nFjpysdTPBGr7CUQK6eCMyh/Tw0Q2tQwO9Yk7M=";
    };

    # Overrides stock data/config.php — SERVER_NAME/ADDRESSES for this instance,
    # INSTANCES emptied (private, tailnet-only, shouldn't announce itself publicly).
    configPhp = pkgs.writeText "config.php" ''
      <?php
      class config{
        const VERSION = 9;
        const SERVER_NAME = "search";
        const SERVER_SHORT_DESCRIPTION = "4get is a proxy search engine that doesn't suck.";
        const SERVER_LONG_DESCRIPTION = null;
        const DEFAULT_THEME = "Dark";
        const API_ENABLED = true;
        const DISPLAY_ERRORS = false;
        const FPLAY_ENABLE_API = false;
        const FPLAY_PASSWORD = "cnc";
        const FPLAY_EXTERNAL_ENDPOINT = null;
        const RATELIMIT_BURST = 0;
        const RATELIMIT_IP_SOURCE = false;
        const RATELIMIT_TIME = 2;
        const RATELIMIT_PUNISH = 1;
        const RATELIMIT_PUNISH_API = false;
        const BOT_PROTECTION = 0;
        const CAPTCHA_DATASET = [];
        const HEADER_REGEX = '/bot|wget|curl|python-requests|scrapy|go-http-client|ruby|yahoo|spider|qwant|meta/i';
        const FILTERED_HEADER_KEYS = [];
        const DISALLOWED_SSL = [];
        const MAX_SEARCHES = 100;
        const ADDRESSES = ["https://tursi.vafla.eu"];
        const INSTANCES = [];
        const USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:157.0) Gecko/20100101 Firefox/157.0";
        const USER_AGENT_FRIENDLY = "4get-scrapist";
        const PROXY_DDG = false;
        const PROXY_YAHOO = false;
        const PROXY_YAHOO_JAPAN = false;
        const PROXY_BRAVE = false;
        const PROXY_GOOGLE = false;
        const PROXY_GOOGLE_API = false;
        const PROXY_GOOGLE_CSE = false;
        const PROXY_STARTPAGE = false;
        const PROXY_QWANT = false;
        const PROXY_BAIDU = false;
        const PROXY_COCCOC = false;
        const PROXY_GHOSTERY = false;
        const PROXY_MARGINALIA = false;
        const PROXY_MOJEEK = false;
        const PROXY_SC = false;
        const PROXY_SWISSCOWS = false;
        const PROXY_SPOTIFY = false;
        const PROXY_SOLOFIELD = false;
        const PROXY_PURILI = false;
        const PROXY_WIBY = false;
        const PROXY_CURLIE = false;
        const PROXY_YT = false;
        const PROXY_ARCHIVEORG = false;
        const PROXY_SEPIASEARCH = false;
        const PROXY_ODYSEE = false;
        const PROXY_DAILYMOTION = false;
        const PROXY_VIMEO = false;
        const PROXY_YEP = false;
        const PROXY_PINTEREST = false;
        const PROXY_FLICKR = false;
        const PROXY_PIXABAY = false;
        const PROXY_UNSPLASH = false;
        const PROXY_PEXELS = false;
        const PROXY_FIVEHPX = false;
        const PROXY_VSCO = false;
        const PROXY_SEZNAM = false;
        const PROXY_NAVER = false;
        const PROXY_MWMBL = false;
        const PROXY_FTM = false;
        const PROXY_IMGUR = false;
        const PROXY_CARA = false;
        const PROXY_YANDEX_W = false;
        const PROXY_YANDEX_I = false;
        const PROXY_YANDEX_V = false;
        const PROXY_SAFEBOORU = false;
        const PROXY_KONACHAN = false;
        const PROXY_YANDERE = false;
        const PROXY_TBIB = false;
        const PROXY_GELBOORU = false;
        const GOOGLE_CX_ENDPOINT = "d4e68b99b876541f0";
        const MARGINALIA_API_KEY = null;
        const YEP_USE_API = false;
      }
    '';

    patchedSrc = pkgs.runCommand "4get-patched" { } ''
      cp -r ${src} $out
      chmod -R u+w $out
      cp ${configPhp} $out/data/config.php
    '';

    phpPkg = pkgs.php.withExtensions ({ enabled, all }: enabled ++ (with all; [ imagick apcu curl mbstring ]));

    stateDir = "/var/lib/4get";
  in {
    users.users.fourget = {
      isSystemUser = true;
      group = "fourget";
    };
    users.groups.fourget = { };

    # PHP's docroot must be writable (favicon.php caches to ./icons/) — nix store is
    # read-only, so sync the build into /var/lib/4get instead of serving in-place.
    # --exclude=icons preserves the favicon cache across rebuilds/restarts.
    systemd.services.fourget-sync = {
      description = "Sync 4get source into writable state directory";
      before = [ "phpfpm-fourget.service" ];
      requiredBy = [ "phpfpm-fourget.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "fourget";
        Group = "fourget";
        StateDirectory = "4get";
      };
      script = ''
        mkdir -p ${stateDir}/icons
        ${pkgs.rsync}/bin/rsync -a --delete --exclude=icons/ ${patchedSrc}/ ${stateDir}/
      '';
    };

    services.phpfpm.pools.fourget = {
      user = "fourget";
      group = "fourget";
      phpPackage = phpPkg;
      settings = {
        "listen.owner" = "fourget";
        "listen.group" = "fourget";
        "listen.mode" = "0660";
        pm = "dynamic";
        "pm.max_children" = 10;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 4;
        "env[LD_PRELOAD]" = "${pkgs.curl-impersonate}/lib/libcurl-impersonate.so";
        "env[CURL_IMPERSONATE]" = "ff117";
      };
    };

    users.users.nginx.extraGroups = [ "fourget" ];

    services.nginx = {
      enable = true;
      virtualHosts."4get-local" = {
        listen = [{ addr = "0.0.0.0"; port = 8098; }];
        root = stateDir;
        extraConfig = ''
          access_log off;
          error_log /dev/null;
        '';
        locations."@php" = {
          tryFiles = "$uri.php $uri/index.php =404";
          extraConfig = ''
            fastcgi_pass unix:${config.services.phpfpm.pools.fourget.socket};
            fastcgi_index index.php;
            include ${pkgs.nginx}/conf/fastcgi.conf;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_intercept_errors on;
          '';
        };
        locations."/" = {
          tryFiles = "$uri @php";
        };
      };
    };
  };
}
