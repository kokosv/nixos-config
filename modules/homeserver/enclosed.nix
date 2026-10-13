{ lib, ... }: {
  options.homeserver.enclosed = lib.mkOption { type = lib.types.deferredModule; };

  config.homeserver.enclosed = { config, ... }: {
    age.secrets.enclosed-env = {
      file = ../../secrets/enclosed-env.age;
      mode = "0400";
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/enclosed 0750 root root -"
    ];

    virtualisation.oci-containers.containers.enclosed = {
      image = "corentinth/enclosed:latest";
      ports = [ "8787:8787" ];
      environmentFiles = [ config.age.secrets.enclosed-env.path ];
      environment = {
        PUBLIC_BASE_API_URL = "https://taina.vafla.eu";
        PUBLIC_IS_AUTHENTICATION_REQUIRED = "true";
      };
      volumes = [ "/var/lib/enclosed:/app/.data" ];
    };
  };
}
