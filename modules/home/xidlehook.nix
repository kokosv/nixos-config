{ lib, ... }: {
  options.homeManager.xidlehook = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.xidlehook = { pkgs, ... }: {
    home.packages = [ pkgs.xidlehook ];

    systemd.user.services.xidlehook = {
      Unit = {
        Description = "xidlehook - idle screen off and hibernate";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = ''
          ${pkgs.xidlehook}/bin/xidlehook \
            --not-when-audio \
            --timer 600 \
              '${pkgs.xset}/bin/xset dpms force off' \
              "" \
            --timer 900 \
              '${pkgs.systemd}/bin/systemctl hibernate' \
              ""
        '';
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
