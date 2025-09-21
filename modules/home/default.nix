{ config, pkgs, lib, ... }:

{
  imports = [
    ./i3.nix
    ./rofi.nix
    ./i3blocks.nix
    ./kitty.nix
    ./curl.nix
    ./wget.nix
    ./ranger.nix
    ./btop.nix
    ./eza.nix
    ./fzf.nix
    ./git.nix
  ];
  
  # Default settings for all modules
  options.home.modules = {
    i3.enable = lib.mkEnableOption "i3 window manager" // { default = true; };
    rofi.enable = lib.mkEnableOption "rofi application launcher" // { default = true; };
    i3blocks.enable = lib.mkEnableOption "i3blocks status bar" // { default = true; };
    kitty.enable = lib.mkEnableOption "kitty terminal" // { default = true; };
    curl.enable = lib.mkEnableOption "curl utility" // { default = true; };
    wget.enable = lib.mkEnableOption "wget utility" // { default = true; };
    ranger.enable = lib.mkEnableOption "ranger file manager" // { default = true; };
    btop.enable = lib.mkEnableOption "btop system monitor" // { default = true; };
    eza.enable = lib.mkEnableOption "eza file lister" // { default = true; };
    fzf.enable = lib.mkEnableOption "fzf fuzzy finder" // { default = true; };
    git.enable = lib.mkEnableOption "git version control" // { default = true; };
  };
}
