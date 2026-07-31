{ lib, pkgs, ... }: {
  options.nixos.pipewire = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.pipewire = {
    environment.systemPackages = with pkgs; [ pipewire ];

    services.pulseaudio.enable = false;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig.pipewire."99-silent-bell.conf"."context.properties"."module.x11.bell" = false;
    };
  };
}
