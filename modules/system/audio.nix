{ config, pkgs, lib, ... }:

let
  cfg = config.modules.audio;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ pipewire ];
    
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      extraConfig = {
        pipewire."99-silent-bell.conf" = {
            "context.properties" = {
            "module.x11.bell" = false;
          };
        };
      };

    };

  };
}
