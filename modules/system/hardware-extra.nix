{ config, pkgs, lib, ... }:

let
  cfg = config.modules.hardware-extra;
in {
  config = lib.mkIf cfg.enable {
    hardware = {
      # enable opengl (usually by default)
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          libvdpau-va-gl
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [
          intel-media-driver
          libvdpau-va-gl
        ];
      };

      bluetooth = {
        enable = true;
        powerOnBoot = false;
      };
    };
  };
}
