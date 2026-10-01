{ lib, ... }: {
  options.vps.acme = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.acme = { config, ... }: {
    age.secrets.desec-token.file = ../../secrets/desec-token.age;

    security.acme = {
      acceptTerms = true;
      defaults.email = "kaloyansv@gmail.com";
      certs."vafla.eu" = {
        domain = "*.vafla.eu";
        extraDomainNames = [ "vafla.eu" "map.mc.vafla.eu" ];
        dnsProvider = "desec";
        dnsPropagationCheck = true;
        environmentFile = config.age.secrets.desec-token.path;
        group = config.services.nginx.group;
      };
    };
  };
}
