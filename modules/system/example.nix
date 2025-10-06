{ config, pkgs, lib, ... }:

let
  cfg = config.modules.#example;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ #example ];
    
  };
}
