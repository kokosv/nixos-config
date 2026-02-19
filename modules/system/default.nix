{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./dm.nix
    ./i3.nix
    ./audio.nix

    ./tailscale.nix
    ./moonlight.nix

    ./services.nix
    ./others.nix
  ];

  # Default settings for all modules
  options.modules = {
    dm.enable = lib.mkEnableOption "display manager" // {
      default = true;
    };
    i3.enable = lib.mkEnableOption "i3 window manager" // {
      default = true;
    };
    audio.enable = lib.mkEnableOption "audio - pipewire" // {
      default = true;
    };

    tailscale.enable = lib.mkEnableOption "mesh vpn" // {
      default = true;
    };
    moonlight.enable = lib.mkEnableOption "sunshine client" // {
      default = true;
    };

    services.enable = lib.mkEnableOption "services configs" // {
      default = true;
    };
    others.enable = lib.mkEnableOption "configless stuff" // {
      default = true;
    };
  };
}
