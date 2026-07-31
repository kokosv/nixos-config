{ lib, ... }: {
  options.homeManager.usrDir = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.usrDir = { config, ... }: {
    xdg.userDirs = {
      enable = true;
      setSessionVariables = true;
      createDirectories = true;

      publicShare = null;
      templates = null;
      music = null;
      desktop = null;

      documents = "${config.home.homeDirectory}/doc";
      download = "${config.home.homeDirectory}/dwl";
      pictures = "${config.home.homeDirectory}/pic";
      videos = "${config.home.homeDirectory}/vid";

      extraConfig = {
        PROJECTS = "${config.home.homeDirectory}/prj";
        MOUNT = "${config.home.homeDirectory}/mnt/usb";
      };
    };
  };
}
