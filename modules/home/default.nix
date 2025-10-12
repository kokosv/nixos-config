{ config, pkgs, lib, ... }:

{
  imports = [

    # visual environment
    ./i3-style.nix
    ./i3blocks.nix
    ./i3-session.nix

    # terminal
    ./kitty.nix

    # shell aliases and func
    ./shell.nix

    # browser
    ./firefox.nix

    # app search
    ./rofi.nix

    # editor
    ./neovim.nix

    # clipboard manager
    ./clipse.nix

    # default usr dir
    ./usr-dir.nix

    # cli tools
    ./git.nix
    ./ssh.nix
    ./btop.nix
    ./eza.nix
    ./fzf.nix
    ./fusuma.nix

    # cli tools without customization
    ./cli.nix
  ];

  # Default settings for all modules
  options.home.modules = {

    i3-style.enable = lib.mkEnableOption "i3wm styling" // { default = true; };
    i3blocks.enable = lib.mkEnableOption "i3blocks status bar" // { default = true; };
    i3-session.enable = lib.mkEnableOption "i3-session proper startup" // { default = true; };

    kitty.enable = lib.mkEnableOption "kitty terminal" // { default = true; };
    shell.enable = lib.mkEnableOption "shell aliases and func" // { default = true; };
    firefox.enable = lib.mkEnableOption "browser" // { default = true; };
    rofi.enable = lib.mkEnableOption "rofi application launcher" // { default = true; };
    neovim.enable = lib.mkEnableOption "terminal text editor" // { default = true; };
    clipse.enable = lib.mkEnableOption "clipboard manager" // { default = true; };

    git.enable = lib.mkEnableOption "git version control" // { default = true; };
    ssh.enable = lib.mkEnableOption "ssh client" // { default = true; };
    btop.enable = lib.mkEnableOption "btop system monitor" // { default = true; };
    eza.enable = lib.mkEnableOption "eza file lister" // { default = true; };
    fzf.enable = lib.mkEnableOption "fzf fuzzy finder" // { default = true; };
    fusuma.enable = lib.mkEnableOption "multitouch gestures for x11" // { default = true; };
    usr-dir.enable = lib.mkEnableOption "default usr dir" // { default = true; };

    cli.enable = lib.mkEnableOption "cli toolsw without customization" // { default = true; };
  };
}
