{ lib, ... }: {
  options.vps.nginx = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.nginx = { pkgs, ... }:
  let
    nginxWithGeoip = pkgs.nginx.override { modules = [ pkgs.nginxModules.geoip2 ]; };
  in
  {
    environment.systemPackages = [ nginxWithGeoip ];
    services.nginx = {
      enable = true;
      package = nginxWithGeoip;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      commonHttpConfig = ''
        geoip2 /var/lib/geoip/dbip-country-lite.mmdb {
          auto_reload 1d;
          $geoip2_country_code default=XX country iso_code;
        }

        map $geoip2_country_code $geo_blocked {
          default 0;
          US      1;
          CN      1;
          RU      1;
          UA      1;
          BY      1;
          GB      1;
        }
      '';
    };
  };
}
