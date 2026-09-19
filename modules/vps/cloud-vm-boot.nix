{ lib, ... }: {
  options.vps.cloudVmBoot = lib.mkOption { type = lib.types.deferredModule; };

  # Boot config for a typical BIOS-booted KVM/QEMU cloud VM (Hetzner,
  # generic VPS providers, etc). Assumes disko lays out a GPT disk with
  # an ESP mounted at /boot, and boots via GRUB in "nodev" mode.
  config.vps.cloudVmBoot = {
    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };
    boot.loader.systemd-boot.enable = false;

    boot.initrd.availableKernelModules = [ "virtio" "virtio_blk" "virtio_pci" ];
    boot.initrd.kernelModules = [ "virtio" "virtio_blk" "virtio_pci" ];
    boot.kernelModules = [ "virtio" "virtio_blk" "virtio_pci" ];

    boot.kernelParams = [
      "console=ttyS0"
      "console=tty0"
    ];
  };
}
