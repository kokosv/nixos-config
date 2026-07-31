{ lib, ... }: {
  options.homeManager.i3Session = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.i3Session = { pkgs, ... }: {
    systemd.user = {
      targets.i3-session = {
        Unit = {
          Description = "i3 window manager session";
          BindsTo = [ "graphical-session.target" ];
          Before = [ "graphical-session.target" ];
          DefaultDependencies = false;
          StopWhenUnneeded = true;
        };
      };

      services.i3-session = {
        Unit = {
          Description = "i3 window manager session";
          PartOf = [ "i3-session.target" ];
          Wants = [ "i3-session.target" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/true";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
