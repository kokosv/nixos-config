{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.i3blocks;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ i3blocks ]; 
    
    xdg.configFile."i3blocks/config".text = ''
      # Your personal i3blocks configuration
      [memory]
      command=free -h | awk '/^Mem/ {print $3"/"$2}'
      interval=30

      [time]
      command=date '+%Y-%m-%d %H:%M:%S'
      interval=1
    '';
  };
}
