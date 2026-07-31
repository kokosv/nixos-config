{ lib, pkgs, ... }: {
  options.nixos.zsh = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.zsh = {
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
