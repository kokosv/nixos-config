{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.i3blocks;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ i3blocks ]; 

    # after editing the i3blocks and rebuilding 
    # run i3-msg restart   
    xdg.configFile."i3blocks/config".text = ''

      [network]
      command=nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 || echo "wired"
      interval=30
      signal=1
 
      [memory]
      command=free -h | awk '/^Mem/ {print $3"/"$2}'
      interval=30

      [date]
      command=date '+%Y-%m-%d'
      interval=once
 
      [time]
      command=date '+%H:%M:%S'
      interval=1

    '';

  };
}

