{ lib, ... }: {
  options.homeserver.cryptpad = lib.mkOption { type = lib.types.deferredModule; };

  config.homeserver.cryptpad = { pkgs, ... }: {
    services.cryptpad = {
      enable = true;
      configureNginx = false; # nginx lives on the VPS, not here
      settings = {
        httpUnsafeOrigin = "https://dok.vafla.eu";
        httpSafeOrigin = "https://dokument.vafla.eu"; # sandbox domain, required for iframe origin isolation
        httpAddress = "0.0.0.0"; # must be reachable from the VPS over tailscale
        adminKeys = [ "[koko@dok.vafla.eu/MrcFzWCTcQEQw3wFBAvub52fNEJfmAWf+hNxkYcTxEM=]" ];
      };
    };

    # Blocks anonymous/unregistered pad creation and storage. Registered users can
    # still create/store; closing registration itself is a manual admin-panel step
    # (can't be done until the first account exists).
    # Written via ExecStartPre, not systemd.tmpfiles: cryptpad.service's StateDirectory
    # is owned by its own DynamicUser, and tmpfiles refuses to manage any path nested
    # inside a directory it doesn't own ("unsafe path transition" check) — it silently
    # no-ops instead of erroring. ExecStartPre runs as that same DynamicUser inside the
    # same chroot as the main process, so it can write there directly with no such check.
    systemd.services.cryptpad.serviceConfig.ExecStartPre = [
      "${pkgs.coreutils}/bin/mkdir -p /var/lib/cryptpad/customize"
      "${pkgs.coreutils}/bin/install -m0644 ${
        pkgs.writeText "cryptpad-application-config.js" ''
          // Overrides on top of customize.dist/application_config.js's default wrapper —
          // AppConfig is injected as a function parameter (AMD/CommonJS module), not a
          // global, so this can't just be bare assignment statements.
          (() => {
          const factory = (AppConfig) => {
              AppConfig.disableAnonymousPadCreation = true;
              AppConfig.disableAnonymousStore = true;
              return AppConfig;
          };

          if (typeof(module) !== 'undefined' && module.exports) {
              module.exports = factory(
                  require('../www/common/application_config_internal.js')
              );
          } else if ((typeof(define) !== 'undefined' && define !== null) && (define.amd !== null)) {
              define(['/common/application_config_internal.js'], factory);
          }
          })();
        ''
      } /var/lib/cryptpad/customize/application_config.js"
    ];
  };
}
