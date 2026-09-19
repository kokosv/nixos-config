{ lib, ... }: {
  options.vps.basePackages = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.basePackages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      neovim
      git
      ranger
      file
    ];
  };
}
