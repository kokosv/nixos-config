{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.firefox;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ firefox ]; 
    
    programs.firefox = {
      enable = true;
      
      profiles.default = {
        
        search = {
          default = "ddg";
          privateDefault = "ddg";
	  force = true; # force overide to skip having to delete the search.json.mozlz4.hm-backup file every rebuild
        };

        settings = {
          "nglayout.enable_drag_images" = false;
	  "security.remote_settings.crlite_filters.enabled" = true;
	  "app.normandy.enabled" = false;
	  "extensions.pocket.enabled" = false;

	  "sidebar.revamp" = true;
	  "sidebar.verticalTabs" = true;

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
        };
      };
    };
  };
}
