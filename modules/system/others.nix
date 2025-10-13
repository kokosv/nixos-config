{ config, pkgs, lib, ... }:

let
  cfg = config.modules.others;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # wireless daemon
      iwd 
      # pci devices
      pciutils
    ];
    
  };
}
