{ lib, ... }: {
  options.homeserver.authentik = lib.mkOption { type = lib.types.deferredModule; };

  config.homeserver.authentik = { config, ... }: {
    age.secrets.authentik-secret-key = {
      file = ../../secrets/authentik-secret-key.age;
      mode = "0400";
    };
    age.secrets.authentik-postgres-password = {
      file = ../../secrets/authentik-postgres-password.age;
      owner = "postgres";
      mode = "0400";
    };
    age.secrets.authentik-bootstrap = {
      file = ../../secrets/authentik-bootstrap.age;
      mode = "0400";
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "authentik" ];
      ensureUsers = [
        {
          name = "authentik";
          ensureDBOwnership = true;
        }
      ];
    };

    # ensureUsers can't set a password declaratively — sync it from the agenix
    # secret into Postgres on every boot instead.
    systemd.services.authentik-postgres-password = {
      description = "Sync authentik's Postgres role password from agenix secret";
      after = [ "postgresql.service" "postgresql-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
      };
      script = ''
        pass=$(cut -d= -f2- < ${config.age.secrets.authentik-postgres-password.path})
        ${config.services.postgresql.package}/bin/psql -c "ALTER ROLE authentik WITH PASSWORD '$pass';"
      '';
    };

    services.redis.servers.authentik = {
      enable = true;
      port = 6379;
      bind = "127.0.0.1";
    };

    # authentik's container image runs as UID 1000 internally; with podman
    # --network=host (no userns remap), that's UID 1000 on the host too.
    systemd.tmpfiles.rules = [
      "d /var/lib/authentik/media 0750 1000 1000 -"
      "d /var/lib/authentik/templates 0750 1000 1000 -"
      "d /var/lib/authentik/certs 0750 1000 1000 -"
    ];

    virtualisation.oci-containers.containers = {
      authentik-server = {
        image = "ghcr.io/goauthentik/server:2025.12.6";
        cmd = [ "server" ];
        extraOptions = [ "--network=host" ];
        environmentFiles = [
          config.age.secrets.authentik-secret-key.path
          config.age.secrets.authentik-postgres-password.path
          config.age.secrets.authentik-bootstrap.path
        ];
        environment = {
          AUTHENTIK_POSTGRESQL__HOST = "127.0.0.1";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
          AUTHENTIK_REDIS__HOST = "127.0.0.1";
          AUTHENTIK_REDIS__PORT = "6379";
        };
        volumes = [
          "/var/lib/authentik/media:/media"
          "/var/lib/authentik/templates:/templates"
          "/var/lib/authentik/certs:/certs"
        ];
      };

      authentik-worker = {
        image = "ghcr.io/goauthentik/server:2025.12.6";
        cmd = [ "worker" ];
        extraOptions = [ "--network=host" ];
        environmentFiles = [
          config.age.secrets.authentik-secret-key.path
          config.age.secrets.authentik-postgres-password.path
          config.age.secrets.authentik-bootstrap.path
        ];
        environment = {
          AUTHENTIK_POSTGRESQL__HOST = "127.0.0.1";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
          AUTHENTIK_REDIS__HOST = "127.0.0.1";
          AUTHENTIK_REDIS__PORT = "6379";
        };
        volumes = [
          "/var/lib/authentik/media:/media"
          "/var/lib/authentik/templates:/templates"
          "/var/lib/authentik/certs:/certs"
        ];
      };
    };
  };
}
