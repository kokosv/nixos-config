{ config, pkgs, lib, ... }:

{
  imports = [

    # visual environment
    ./i3-style.nix
    ./i3-session.nix

    # compositor
    ./picom.nix

    # top bar
    ./polybar/polybar.nix

    # terminal
    ./kitty.nix

    # shell aliases and func
    ./shell.nix

    # browser
    ./firefox.nix

    # app/commands search
    ./rofi/rofi.nix
    ./rofi/apps.nix

    # editor
    ./nvim/nixvim.nix

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
    ./khal.nix
    ./dunst.nix
    ./direnv.nix

    # configless stuff
    ./others.nix
  ];

  # Default settings for all modules
  options.home.modules = {

    i3-style.enable = lib.mkEnableOption "i3wm styling" // { default = true; };
    i3-session.enable = lib.mkEnableOption "i3-session proper startup" // { default = true; };
    picom.enable = lib.mkEnableOption "compositor" // { default = true; };
    polybar.enable = lib.mkEnableOption "top bar" // { default = true; };
    kitty.enable = lib.mkEnableOption "terminal" // { default = true; };
    shell.enable = lib.mkEnableOption "shell aliases and func" // { default = true; };
    firefox.enable = lib.mkEnableOption "browser" // { default = true; };
    rofi.enable = lib.mkEnableOption "application launcher" // { default = true; };
    apps.enable = lib.mkEnableOption "add tui apps to rofi" // { default = true; };
    nvim.enable = lib.mkEnableOption "tui text editor" // { default = true; }; 
    
    clipse.enable = lib.mkEnableOption "tui clipboard manager" // { default = true; };

    usr-dir.enable = lib.mkEnableOption "default usr dir" // { default = true; };

    git.enable = lib.mkEnableOption "git version control" // { default = true; };
    ssh.enable = lib.mkEnableOption "ssh client" // { default = true; };
    btop.enable = lib.mkEnableOption "tui system monitor" // { default = true; };
    eza.enable = lib.mkEnableOption "ls replacement" // { default = true; };
    fzf.enable = lib.mkEnableOption "tui fuzzy finder" // { default = true; };
    fusuma.enable = lib.mkEnableOption "multitouch gestures for x11" // { default = true; };
    khal.enable = lib.mkEnableOption "tui calendar" // { default = true; };
    dunst.enable = lib.mkEnableOption "notifications daemon" // { default = true; };
    direnv.enable = lib.mkEnableOption "shell extension" // { default = true; };

    others.enable = lib.mkEnableOption "configless stuff" // { default = true; };
  };
}
