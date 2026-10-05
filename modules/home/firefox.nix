{ lib, ... }: {
  options.homeManager.firefox = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.firefox = { pkgs, config, ... }: {
    programs.firefox = {
      enable = true;

      # configPath = ".mozilla/firefox"; # legacy
      configPath = "${config.xdg.configHome}/mozilla/firefox";

      # Registers the OpenSC PKCS#11 module (smart card middleware, see
      # modules/system/smartcard.nix) so the B-Trust card/token shows up under
      # about:preferences#privacy -> Security Devices without a manual "Load" step.
      policies = {
        SecurityDevices = {
          "OpenSC PKCS#11" = "${pkgs.opensc}/lib/opensc-pkcs11.so";
        };
      };

      profiles.default = {

        search = {
          default = "ddg";
          privateDefault = "ddg";
          force = true; # force override to skip having to delete the search.json.mozlz4.hm-backup file every rebuild
        };

        userContent = ''
          /* remove Firefox logo in home page */
          .logo-and-wordmark {
          display: none !important;
          }

          /* ==========================================================================
             userContent.css - square Firefox's OWN internal pages (Settings)

             The Settings page (about:preferences) is not a chrome:// window, so
             userChrome.css cannot style it; it needs userContent.css.

             The guard below limits every rule to the listed about: pages, so normal
             websites are NOT affected. Delete any line from the list
             if you don't want that page squared (for example about:newtab / about:home).
             ========================================================================== */

          @-moz-document
            url-prefix("about:preferences"),
            url-prefix("about:settings"),
            url-prefix("about:addons"),
            url-prefix("about:config"),
            url-prefix("about:logins"),
            url-prefix("about:downloads"),
            url-prefix("about:firefoxview"),
            url-prefix("about:privatebrowsing"),
            url-prefix("about:newtab"),
            url-prefix("about:home") {

            :root,
            * {
              --border-radius-xsmall: 0px !important;
              --border-radius-small: 0px !important;
              --border-radius-medium: 0px !important;
              --border-radius-large: 0px !important;
              --border-radius-xlarge: 0px !important;
              --border-radius-circle: 0px !important;
              --border-radius-pill: 0px !important;
              --button-border-radius: 0px !important;
              --input-border-radius: 0px !important;
              --card-border-radius: 0px !important;
            }

            *,
            *::before,
            *::after {
              border-radius: 0 !important;
            }

            *::part(button),
            *::part(input),
            *::part(container),
            *::part(content),
            *::part(card),
            *::part(label) {
              border-radius: 0 !important;
            }
          }
        '';

        userChrome = ''
          /* ==========================================================================
             userChrome.css - square every corner of the Firefox GUI

             IMPORTANT: no default @namespace line here on purpose. Firefox's main
             window root is an HTML element, so a default XUL namespace would make
             ":root" and "*" match nothing in the main window.

             The @-moz-document guard keeps all of this limited to Firefox's own
             windows (chrome://), so websites are never affected.
             ========================================================================== */

          @-moz-document url-prefix("chrome://") {

            /* ------------------------------------------------------------------------
               1. Radius variables, set on EVERY element.
                  Firefox sets some of these directly on elements such as #urlbar,
                  so setting them only on :root is not enough. Variables also pass
                  into shadow DOM (sidebar buttons, menus, panels).
               ------------------------------------------------------------------------ */
            :root,
            * {
              --tab-border-radius: 0px !important;
              --tab-group-border-radius: 0px !important;
              --toolbarbutton-border-radius: 0px !important;
              --toolbarbutton-inner-border-radius: 0px !important;
              --urlbar-border-radius: 0px !important;
              --urlbar-margin-inline: 0px !important;
              --toolbar-field-border-radius: 0px !important;
              --arrowpanel-border-radius: 0px !important;
              --panel-border-radius: 0px !important;
              --menuitem-border-radius: 0px !important;
              --button-border-radius: 0px !important;
              --input-border-radius: 0px !important;
              --card-border-radius: 0px !important;
              --border-radius-xsmall: 0px !important;
              --border-radius-small: 0px !important;
              --border-radius-medium: 0px !important;
              --border-radius-large: 0px !important;
              --border-radius-xlarge: 0px !important;
              --border-radius-circle: 0px !important;
              --border-radius-pill: 0px !important;
              --border-radius-toolbar-button: 0px !important;
            }

            /* ------------------------------------------------------------------------
               2. Direct rule on every element and pseudo-element.
                  Covers: tabs, vertical tabs, sidebar, address bar, search bar,
                  toolbar buttons, burger menu, bookmarks bar, tab group popups,
                  context menus, dialogs, find bar, downloads panel, etc.
               ------------------------------------------------------------------------ */
            *,
            *::before,
            *::after {
              border-radius: 0 !important;
            }

            /* ------------------------------------------------------------------------
               3. Shadow-DOM "parts": the visible box of popups and menus
                  (hover popups, burger menu, bookmark folders, tab group previews).
               ------------------------------------------------------------------------ */
            *::part(content),
            *::part(arrowscrollbox),
            *::part(scrollbox),
            *::part(scrollbutton-up),
            *::part(scrollbutton-down),
            *::part(button),
            *::part(input),
            *::part(container),
            panel::part(content),
            menupopup::part(content),
            menupopup::part(arrowscrollbox) {
              border-radius: 0 !important;
            }
          }
        '';

        settings = {
          # load custom css from /chrome/usrContent.css
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          "widget.use-xdg-desktop-portal.file-picker" = 1;
          "nglayout.enable_drag_images" = false;
          "security.remote_settings.crlite_filters.enabled" = true;
          "app.normandy.enabled" = false;
          "extensions.pocket.enabled" = false;

          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;

          # new firefox design
          "browser.nova.enabled" = false;

          "browser.tabs.groups.hoverPreview.enabled" = false;
          "browser.tabs.hoverPreview.enabled" = false;
          "browser.tabs.hoverPreview.showThumbnails" = false;
          "browser.search.openintab" = true;
          "browser.search.region" = "BG";
          "browser.search.widget.inNavBar" = true;
          "browser.migrate.bookmarks.html.enabled" = false;

          # home screen (if disabled it's just blank)
          "browser.newtabpage.enabled" = true;
          "browser.newtabpage.pinned" = false;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;

          "browser.ping-centre.telemetry" = false;
          "browser.vpn_promo.enabled" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.setDesktopBackground" = false;
          "browser.safebrowsing.downloads.remote.enabled" = false;
          "browser.download.dir" = "~/downloads";

          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.cryptomining.enabled" = true;
          "privacy.trackingprotection.fingerprinting.enabled" = true;

          "datareporting.policy.dataSubmissionEnabled" = false;
          "datareporting.healthreport.uploadEnabled" = false;

          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.updatePing" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.telemetry.coverage.opt-out" = true;
          "toolkit.telemetry.reportingpolicy.firstRun" = false;
          "toolkit.telemetry.shutdownPingSender.enabledFirstsession" = false;

          "toolkit.coverage.opt-out" = true;
          "toolkit.coverage.endpoint.base" = "";

          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;
        };
      };
    };
  };
}
