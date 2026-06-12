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
    stateVersion = "25.05";
    username = "koko";
    homeDirectory = "/home/koko";
  };

  # Enable/disable home modules - example: "clipse.enable = false;"
  home.modules = {
    clipse.enable = false;
    shell.enable = false;
  };
}
