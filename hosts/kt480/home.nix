{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ../../modules/home/default.nix
  ];

  programs.home-manager.enable = true;

  home = {
    stateVersion = "25.11";
    username = "koko";
    homeDirectory = "/home/koko";
  };

  # Enable/disable home modules
  home.modules = {
    #fzf.enable = false;
  };
}
