{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.ssh-client;
in {
  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      # matchBlocks."*"
    };
  };
}
