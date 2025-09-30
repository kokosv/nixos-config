{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.ssh;
in {
  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
    };
  };
}
