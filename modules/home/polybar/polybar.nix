{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.polybar;

  color = "#9b9b9b"; # light gray
in
{
  config = lib.mkIf cfg.enable {

    services.polybar = {
      enable = true;

      package = pkgs.polybar.override {
        pulseSupport = true;
        i3Support = true;
      };

      script = "polybar main &";

      config = {
        "bar/main" = {
          monitor = "\${env:MONITOR:}";
          bottom = false;

          width = "100%";
          height = "20";
          radius = "0.0";

          border-top-size = 1;
          border-bottom-size = 1;
          border-left-size = 1;
          border-right-size = 1;

          border-color = color;

          background = "#00000000"; # black

          # space between bar and modules
          padding-left = 0;
          padding-right = 2;
          padding-top = 0;
          padding-bottom = 0;

          # space between modules
          module-margin-left = 1;
          module-margin-right = 1;

          modules-left = [
            "i3"
          ];

          modules-right = [
            "internet"
            "bluetooth"
            "mic"
            "volume"
            "brightness"
            "battery1"
            "battery0"
            # "keyboard"
            "time"
            "date"
            "powermenu"
          ];

          separator = "│";

          font-0 = "DepartureMono Nerd Font:size=12;2";
          wm-name = "i3";
          locale = "bg_BG.UTF-8";

          enable-ipc = true;
        };

        "module/i3" = {
          type = "internal/i3";

          label-focused = "%index%";
          label-unfocused = "%index%";
          label-visible = "%index%";
          label-urgent = "%index%";

          label-focused-foreground = color;
          label-unfocused-foreground = "#666666"; # dark gray
          label-urgent-foreground = "#FF6B6B"; # red

          index-sort = true;

          label-separator = "│";
          label-separator-foreground = color;
          # label-separator-padding = 1;

          label-focused-padding = 2;
          label-unfocused-padding = 2;
          label-urgent-padding = 2;
        };

        "module/date" = {
          type = "custom/script";
          exec = "${pkgs.writeShellScript "date-display" ''
            #!/run/current-system/sw/bin/bash
            echo "$(${pkgs.coreutils}/bin/date +"%Y-%m-%d")"
          ''}";
          interval = 5;
          label = "%output%";
          label-foreground = color;
          click-left = "${pkgs.writeShellScript "calendar-popup" ''
            ${pkgs.yad}/bin/yad --calendar --undecorated --fixed --close-on-unfocus --no-buttons \
              --width=222 --height=193 --title="yad-calendar" \
              --posx=-1 --posy=30 &
          ''}";
        };

        "module/time" = {
          type = "internal/date";
          time = "%H:%M:%S";
          time-alt = "%H:%M:%S";
          label = "%time%";
          label-foreground = color;
          interval = 1;
        };

        "module/battery0" = {
          type = "custom/script";
          exec = "${pkgs.writeShellScript "battery-custom" ''
            #!/run/current-system/sw/bin/bash
            while true; do
              if [ -f /sys/class/power_supply/BAT0/capacity ]; then
                capacity=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
                if [ -n "$capacity" ] && [ "$capacity" -ge 0 ] 2>/dev/null; then
                  if [ "$capacity" -eq 100 ]; then icon="󰁹"
                  elif [ "$capacity" -ge 90 ]; then icon="󰂂"
                  elif [ "$capacity" -ge 80 ]; then icon="󰂁"
                  elif [ "$capacity" -ge 70 ]; then icon="󰂀"
                  elif [ "$capacity" -ge 60 ]; then icon="󰁿"
                  elif [ "$capacity" -ge 50 ]; then icon="󰁾"
                  elif [ "$capacity" -ge 40 ]; then icon="󰁽"
                  elif [ "$capacity" -ge 30 ]; then icon="󰁼"
                  elif [ "$capacity" -ge 20 ]; then icon="󰁻"
                  elif [ "$capacity" -ge 10 ]; then icon="󰁺"
                  else icon="󰂃"
                  fi
                  echo "$icon $capacity%"
                else
                  echo "󰂃 ?%"
                fi
              else
                echo "󱉞 ?"
              fi
              ${pkgs.coreutils}/bin/sleep 60
            done
          ''}";
          interval = "once";
          tail = true;
          label = "[0]%output%";
          label-foreground = color;
        };

        "module/battery1" = {
          type = "custom/script";
          exec = "${pkgs.writeShellScript "battery-custom" ''
            #!/run/current-system/sw/bin/bash
            while true; do
              if [ -f /sys/class/power_supply/BAT1/capacity ]; then
                capacity=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/BAT1/capacity 2>/dev/null)
                if [ -n "$capacity" ] && [ "$capacity" -ge 0 ] 2>/dev/null; then
                  if [ "$capacity" -eq 100 ]; then icon="󰁹"
                  elif [ "$capacity" -ge 90 ]; then icon="󰂂"
                  elif [ "$capacity" -ge 80 ]; then icon="󰂁"
                  elif [ "$capacity" -ge 70 ]; then icon="󰂀"
                  elif [ "$capacity" -ge 60 ]; then icon="󰁿"
                  elif [ "$capacity" -ge 50 ]; then icon="󰁾"
                  elif [ "$capacity" -ge 40 ]; then icon="󰁽"
                  elif [ "$capacity" -ge 30 ]; then icon="󰁼"
                  elif [ "$capacity" -ge 20 ]; then icon="󰁻"
                  elif [ "$capacity" -ge 10 ]; then icon="󰁺"
                  else icon="󰂃"
                  fi
                  echo "$icon $capacity%"
                else
                  echo "󰂃 ?%"
                fi
              else
                echo "󱉞 ?"
              fi
              ${pkgs.coreutils}/bin/sleep 60
            done
          ''}";
          interval = "once";
          tail = true;
          label = "[1]%output%";
          label-foreground = color;
        };

        "module/brightness" = {
          type = "internal/backlight";
          card = "intel_backlight";

          format = "<ramp> <label>";
          label = "%percentage%%";
          label-foreground = color;
          ramp-foreground = color;
          ramp-0 = "󰃞";
          ramp-1 = "󰃝";
          ramp-2 = "󰃟";
          ramp-3 = "󰃠";

          interval = "once";
          poll-interval = 1;

          scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set 10%+";
          scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 10%-";
        };

        "module/volume" = {
          type = "internal/pulseaudio";
          use-ui-max = true;

          format-volume = "<ramp-volume> <label-volume>";
          format-muted = "<label-muted>";

          label-volume = "%percentage%%";
          label-volume-foreground = color;

          label-muted-foreground = color;
          label-muted = "󰝟";

          ramp-volume-foreground = color;
          ramp-volume-0 = "󰕿";
          ramp-volume-1 = "󰖀";
          ramp-volume-2 = "󰕾";

          click-left = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          scroll-up = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          scroll-down = "${pkgs.wireplumber}/bin/wpctl  set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        };

        "module/mic" = {
          type = "custom/script";
          exec = "${pkgs.writeShellScript "mic-status" ''
            #!/run/current-system/sw/bin/bash
            if ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "MUTED"; then
              echo "󰍭"
            else
              echo "󰍬"
            fi
          ''}";
          interval = "once";
          tail = true;
          label = "%output%";
          label-foreground = color;
          click-left = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        };

        "module/bluetooth" = {
          type = "custom/script";
          exec = "${pkgs.writeShellScript "bluetooth-polybar" ''
            #!/run/current-system/sw/bin/bash

            while true; do
              if ! ${pkgs.bluez}/bin/bluetoothctl show 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "Powered: yes"; then
                echo "󰂲"
              else
                devices_paired=$(${pkgs.bluez}/bin/bluetoothctl devices Paired 2>/dev/null | ${pkgs.gnugrep}/bin/grep Device | ${pkgs.coreutils}/bin/cut -d ' ' -f 2)
                connected=""
                battery=""
                
                for device in $devices_paired; do
                  if ${pkgs.bluez}/bin/bluetoothctl info "$device" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "Connected: yes"; then
                    device_name=$(${pkgs.bluez}/bin/bluetoothctl info "$device" 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Alias" | ${pkgs.coreutils}/bin/cut -d ' ' -f 2-)
                    connected="$device_name"
                    battery=$(${pkgs.bluez}/bin/bluetoothctl info "$device" 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Battery Percentage" | ${pkgs.gnugrep}/bin/grep -oP '\(\K[0-9]+')
                    break
                  fi
                done
                
                if [ -n "$connected" ]; then
                  if [ -n "$battery" ] && [ "$battery" -ge 0 ] 2>/dev/null; then
                    if [ "$battery" -le 10 ]; then icon="󰂃"
                    elif [ "$battery" -le 20 ]; then icon="󰁺"
                    elif [ "$battery" -le 30 ]; then icon="󰁻"
                    elif [ "$battery" -le 40 ]; then icon="󰁼"
                    elif [ "$battery" -le 50 ]; then icon="󰁽"
                    elif [ "$battery" -le 60 ]; then icon="󰁾"
                    elif [ "$battery" -le 70 ]; then icon="󰁿"
                    elif [ "$battery" -le 80 ]; then icon="󰂀"
                    elif [ "$battery" -le 90 ]; then icon="󰂁"
                    else icon="󰁹"
                    fi
                    echo "󰂯 $connected $battery% $icon"
                  else
                    echo "󰂯 $connected"
                  fi
                else
                  echo "󰂯"
                fi
              fi
              ${pkgs.coreutils}/bin/sleep 5
            done
          ''}";
          interval = "once";
          tail = true;
          label = "%output%";
          label-foreground = color;
          click-left = "${pkgs.bluez}/bin/bluetoothctl power on";
          click-right = "${pkgs.bluez}/bin/bluetoothctl power off";
        };

        "module/internet" = {
          type = "custom/script";
          exec = "${pkgs.writeShellScript "network-status" ''
            #!/run/current-system/sw/bin/bash

            coreutils="${pkgs.coreutils}/bin"
            grep="${pkgs.gnugrep}/bin"
            nmcli="${pkgs.networkmanager}/bin/nmcli"

            while true; do
              wifi_enabled=$($nmcli radio wifi 2>/dev/null)
              active=$($nmcli -t -f TYPE,NAME connection show --active 2>/dev/null | $grep/grep -v "lo\|tun")
              
              if ! echo "$($nmcli -t -f STATE general status 2>/dev/null)" | $grep/grep -q "connected"; then
                [ "$wifi_enabled" = "enabled" ] && echo "󰤯" || echo "󰤮"
              elif echo "$active" | $grep/grep -q "ethernet"; then
                echo "󰈀"
              elif echo "$active" | $grep/grep -q "wireless"; then
                ssid=$(echo "$active" | $grep/grep "wireless" | $coreutils/cut -d: -f2)
                strength=$($nmcli -t -f SIGNAL device wifi list --rescan no 2>/dev/null | $coreutils/head -n1)
                case "$strength" in
                  [7-9][0-9]|100) echo "󰤨 $ssid";;
                  [5-6][0-9])     echo "󰤥 $ssid";;
                  [2-4][0-9])     echo "󰤢 $ssid";;
                  *)              echo "󰤟 $ssid";;
                esac
              else
                [ "$wifi_enabled" = "enabled" ] && echo "󰤯" || echo "󰤮"
              fi
              
              ${pkgs.coreutils}/bin/sleep 5
            done
          ''}";
          interval = "once";
          tail = true;
          label = "%output%";
          label-foreground = color;
          click-left = "${pkgs.networkmanager}/bin/nmcli radio wifi on";
          click-right = "${pkgs.networkmanager}/bin/nmcli radio wifi off";
        };

        "module/powermenu" = {
          type = "custom/script";
          exec = "echo ⏻";
          interval = 5;
          label = "%output%";
          label-foreground = color;
          click-left = "${pkgs.writeShellScript "power-popup" ''
            #!/run/current-system/sw/bin/bash

            choice=$(printf "Shutdown\nReboot\nSuspend\nHibernate\nLogout\nLock" | \
              ${pkgs.yad}/bin/yad --list \
                --width=120 \
                --height=200 \
                --posx=-1 \
                --posy=30 \
                --fixed \
                --undecorated \
                --no-buttons \
                --close-on-unfocus \
                --skip-taskbar \
                --on-top \
                --title="powermenu" \
                --column="Action" \
                --print-column=1 \
                --button="":0 2>/dev/null | \
              ${pkgs.gnugrep}/bin/grep -E "Shutdown|Reboot|Suspend|Hibernate|Logout|Lock" | \
              ${pkgs.coreutils}/bin/cut -d'|' -f1)

            case "$choice" in
              "Shutdown") ${pkgs.systemd}/bin/poweroff ;;
              "Reboot") ${pkgs.systemd}/bin/reboot ;;
              "Suspend") ${pkgs.systemd}/bin/systemctl suspend ;;
              "Hibernate") ${pkgs.systemd}/bin/systemctl hibernate ;;
              "Logout") i3-msg exit ;;
              "Lock") ${pkgs.xsecurelock}/bin/xsecurelock ;;
            esac
          ''}";
        };
      };
    };
  };
}
