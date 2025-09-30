{ config, pkgs, lib, ... }:

{
  imports = [

    # visual environment
    ./i3-style.nix
    ./i3blocks.nix

    # terminal
    ./kitty.nix

    # global search and select
    ./rofi.nix

    # cli tools
    ./curl.nix
    ./wget.nix
    ./ranger.nix
    ./btop.nix
    ./eza.nix
    ./fzf.nix
    ./git.nix
    ./ssh.nix
  ];

  # Default settings for all modules
  options.home.modules = {

    i3-style.enable = lib.mkEnableOption "i3wm styling" // { default = true; };
    i3blocks.enable = lib.mkEnableOption "i3blocks status bar" // { default = true; };

    kitty.enable = lib.mkEnableOption "kitty terminal" // { default = true; };

    rofi.enable = lib.mkEnableOption "rofi application launcher" // { default = true; };

    curl.enable = lib.mkEnableOption "curl utility" // { default = true; };
    wget.enable = lib.mkEnableOption "wget utility" // { default = true; };
    ranger.enable = lib.mkEnableOption "ranger file manager" // { default = true; };
    btop.enable = lib.mkEnableOption "btop system monitor" // { default = true; };
    eza.enable = lib.mkEnableOption "eza file lister" // { default = true; };
    fzf.enable = lib.mkEnableOption "fzf fuzzy finder" // { default = true; };
    git.enable = lib.mkEnableOption "git version control" // { default = true; };
    ssh.enable = lib.mkEnableOption "ssh client" // { default = true; };
  };
}
