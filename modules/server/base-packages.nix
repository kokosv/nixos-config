{ lib, ... }: {
  options.server.basePackages = lib.mkOption { type = lib.types.deferredModule; };

  config.server.basePackages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      neovim
      git
      ranger
      file
    ];
  };
}
