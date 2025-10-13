{ config, pkgs, lib, ... }:

{
  imports = [
    ./dm.nix
    ./i3.nix
    ./mnt-utils.nix
    ./others.nix
 ];
  
  # Default settings for all modules
  options.modules = {
    dm.enable = lib.mkEnableOption "display manager" // { default = true; };
    i3.enable = lib.mkEnableOption "i3 window manager" // { default = true; };
    mnt-utils.enable = lib.mkEnableOption "mounting tools" // { default = true; }; 
    others.enable = lib.mkEnableOption "configless stuff" // { default = true; }; 
  };
}
