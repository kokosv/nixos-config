{ config, pkgs, lib, ... }:

{
  imports = [
    ./ly.nix
 ];
  
  # Default settings for all modules
  options.modules = {
    ly.enable = lib.mkEnableOption "Ly display manager" // { default = true; };
 };
}
