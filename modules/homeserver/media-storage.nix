{ lib, ... }: {
  options.homeserver.mediaStorage = lib.mkOption { type = lib.types.deferredModule; };

  # Shared layout for the *arr stack: qbittorrent/sonarr/radarr/bazarr/lidarr all need
  # read/write access to the same download + library folders. setgid (02775) so files
  # created by any one of them (different users) inherit the "media" group automatically,
  # instead of needing per-file chown across apps during import.
  config.homeserver.mediaStorage = { ... }: {
    users.groups.media = { };

    systemd.tmpfiles.rules = [
      "d /d03-tv/seriali 02775 root media -"
      "d /d03-tv/downloads 02775 root media -"
      "d /d09-kino/filmi 02775 root media -"
      "d /d09-kino/downloads 02775 root media -"
      "d /d07-muzika/pesni 02775 root media -"
      "d /d07-muzika/downloads 02775 root media -"
    ];
  };
}
