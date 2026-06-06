{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.usr-dir;
in
{
  config = lib.mkIf cfg.enable {

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
        MOUNT = "${config.home.homeDirectory}/mnt";
      };
    };
  };
}
