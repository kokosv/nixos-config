{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.#example;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ #example ];

  };
}
