{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.default-user-dir;
in {
  config = lib.mkIf cfg.enable {
 
    xdg.userDirs = {
      enable = true;

      documents = "\${home.homeDirectory}/documents";
      downloads = "\${home.homeDirectory}/downloads";
      pictures = "\${home.homeDirectory}/pictures";
      videos = "\${home.homeDirectory}/videos";

      extraConfig = {
        XDG_PROJECTS_DIR = "\${home.homeDirectory}/projects";
      };
    };
  };
}
