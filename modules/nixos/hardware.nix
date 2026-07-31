{ lib, pkgs, ... }: {
  options.nixos.hardware = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.hardware = {
    hardware = {
      graphics = {
        enable = true;
        extraPackages = with pkgs; [ intel-media-driver libvdpau-va-gl ];
        extraPackages32 = with pkgs.pkgsi686Linux; [ intel-media-driver libvdpau-va-gl ];
      };
      bluetooth = {
        enable = true;
        powerOnBoot = false;
      };
    };
  };
}
