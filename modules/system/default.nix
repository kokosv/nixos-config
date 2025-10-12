{ config, pkgs, lib, ... }:

{
  imports = [
    ./dm.nix
    ./i3.nix
    ./mount_tools.nix
 ];
  
  # Default settings for all modules
  options.modules = {
    dm.enable = lib.mkEnableOption "display manager" // { default = true; };
    i3.enable = lib.mkEnableOption "i3 window manager" // { default = true; };
    mount_tools.enable = lib.mkEnableOption "mounting tools" // { default = true; }; 
  };
}
