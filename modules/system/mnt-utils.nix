{ config, pkgs, lib, ... }:

let
  cfg = config.modules.mnt-utils;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      e2fsprogs
      exfatprogs
      ntfs3g
      dosfstools
    ];
    
  };
}
