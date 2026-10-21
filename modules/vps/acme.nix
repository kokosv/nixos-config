{ lib, ... }: {
  options.vps.acme = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.acme = { config, ... }: {
    # Holds DESEC_TOKEN (DNS-01 provider) + LEGO_EAB_KID/LEGO_EAB_HMAC (ZeroSSL account
    # binding) — all three env vars lego needs for this cert's issuance, in one file
    # since security.acme only accepts a single environmentFile per cert.
    age.secrets.zerossl-acme-env.file = ../../secrets/zerossl-acme-env.age;

    security.acme = {
      acceptTerms = true;
      defaults.email = "kaloyansv@gmail.com";
      certs."vafla.eu" = {
        domain = "*.vafla.eu";
        extraDomainNames = [ "vafla.eu" "map.mc.vafla.eu" ];
        dnsProvider = "desec";
        dnsPropagationCheck = true;
        environmentFile = config.age.secrets.zerossl-acme-env.path;
        extraLegoFlags = [ "--eab" ];
        server = "https://acme.zerossl.com/v2/DV90";
        group = config.services.nginx.group;
      };
    };
  };
}
