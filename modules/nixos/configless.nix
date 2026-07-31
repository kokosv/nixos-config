{ lib, pkgs, ... }: {
  options.nixos.configless = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.configless = {
    environment.systemPackages = with pkgs; [
      curl
      wget

      # wireless daemon
      iwd

      # pci devices
      pciutils

      # drives health monitoring
      smartmontools

      # mount
      e2fsprogs
      exfatprogs
      ntfs3g
      dosfstools

      kdePackages.breeze-icons
      dconf
    ];

    programs.dconf.enable = true; # gtk theme
  };
}
