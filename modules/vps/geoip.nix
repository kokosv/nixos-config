{ lib, ... }: {
  options.vps.geoip = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.geoip = { pkgs, ... }:
  let
    downloadScript = pkgs.writeShellScript "geoip-download" ''
      set -euo pipefail
      url="https://download.db-ip.com/free/dbip-country-lite-$(${pkgs.coreutils}/bin/date +%Y-%m).mmdb.gz"
      tmp=$(${pkgs.coreutils}/bin/mktemp)
      trap 'rm -f "$tmp"' EXIT
      ${pkgs.curl}/bin/curl -fsSL "$url" | ${pkgs.gzip}/bin/gunzip -c > "$tmp"
      ${pkgs.coreutils}/bin/chmod 644 "$tmp"
      mv "$tmp" /var/lib/geoip/dbip-country-lite.mmdb
    '';
  in
  {
    # Runs only on first boot (when the file is missing). Keeps nginx from starting
    # before the MMDB exists. RemainAfterExit=true means subsequent nginx restarts
    # don't re-trigger the download (the service stays "active" once the file is there).
    systemd.services.geoip-init = {
      description = "Download GeoIP database on first boot";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      before = [ "nginx.service" ];
      wantedBy = [ "nginx.service" ];
      unitConfig.ConditionPathExists = "!/var/lib/geoip/dbip-country-lite.mmdb";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "geoip";
        StateDirectoryMode = "0755";
        ExecStart = downloadScript;
      };
    };

    # Runs monthly to keep the database current.
    systemd.services.geoip-update = {
      description = "Update db-ip.com GeoIP country database";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "geoip";
        StateDirectoryMode = "0755";
        ExecStart = downloadScript;
      };
    };

    systemd.timers.geoip-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "monthly";
        Persistent = true;
      };
    };
  };
}
