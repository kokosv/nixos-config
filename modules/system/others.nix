{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.others;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      curl
      wget
      # wireless daemon
      iwd
      # pci devices
      pciutils
      # dirves health monitoring
      smartmontools
      # mount
      e2fsprogs
      exfatprogs
      ntfs3g
      dosfstools
    ];

  };
}
