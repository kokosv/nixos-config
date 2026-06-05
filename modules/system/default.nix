{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./display-manager.nix
    ./i3.nix
    ./pipewire.nix
    ./upower.nix
    ./greenclip.nix
    ./tailscale.nix
    ./moonlight.nix
    ./trackpoint.nix
    ./xsecurelock.nix

    ./environmental-variables.nix
    ./services.nix
    ./configless.nix
  ];

  # Default settings for all modules
  options.modules = {
    display-manager.enable = lib.mkEnableOption "display manager" // {
      default = true;
    };
    i3.enable = lib.mkEnableOption "i3 window manager" // {
      default = true;
    };
    pipewire.enable = lib.mkEnableOption "audio service" // {
      default = true;
    };
    upower.enable = lib.mkEnableOption "power managment" // {
      default = true;
    };
    greenclip.enable = lib.mkEnableOption "rofi clipboard manager" // {
      default = true;
    };
    tailscale.enable = lib.mkEnableOption "mesh vpn" // {
      default = true;
    };
    moonlight.enable = lib.mkEnableOption "sunshine client" // {
      default = true;
    };
    trackpoint.enable = lib.mkEnableOption "ThinkPad trackpoint" // {
      default = false;
    };
    xsecurelock.enable = lib.mkEnableOption "lock screen with pass" // {
      default = true;
    };

    environmental-variables.enable = lib.mkEnableOption "environmental variables" // {
      default = true;
    };
    services.enable = lib.mkEnableOption "services configs" // {
      default = true;
    };
    configless.enable = lib.mkEnableOption "configless stuff" // {
      default = true;
    };
  };
}
