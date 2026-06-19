{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.zsh;
in
{
  config = lib.mkIf cfg.enable {

    # requred for zsh setup
    environment.systemPackages = with pkgs; [ zsh ];
    environment.shells = with pkgs; [ zsh ];
    environment.pathsToLink = [ "/share/zsh" ];

    users.defaultUserShell = pkgs.zsh;

    programs.zsh = {
      enable = true;

      # DO NOT REMOVE - optimizes the load
      enableCompletion = false;
      enableGlobalCompInit = false;
    };
  };
}
