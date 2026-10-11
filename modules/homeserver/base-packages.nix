{ lib, ... }: {
  options.homeserver.basePackages = lib.mkOption { type = lib.types.deferredModule; };

  config.homeserver.basePackages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      neovim
      git
      ranger
      file
      btop
    ];
  };
}
