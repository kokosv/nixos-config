{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.usr-dir;
in {
  config = lib.mkIf cfg.enable {
 
    xdg.userDirs = {
      enable = true;

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
        XDG_PROJECTS_DIR = "${config.home.homeDirectory}/projects";
	XDG_MOUNT_DIR = "${config.home.homeDirectory}/mnt";
      };
    };
  };
}
