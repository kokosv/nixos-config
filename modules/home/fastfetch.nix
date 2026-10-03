{ lib, ... }: {
  options.homeManager.fastfetch = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.fastfetch = { pkgs, ... }: {
    home.packages = with pkgs; [ fastfetch ];

    programs.fastfetch = {
      enable = true;
      settings = {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        logo = {
          source = "~/.config/fastfetch/penrose-sky-wp.png";
          type = "kitty-direct";
          width = 20;
          height = 20;
          padding = {
            top = 0;
            right = 1;
            left = 3;
          };
        };
        modules = [
          "break"
          {
            type = "host";
            key = "{icon} PC";
            keyColor = "green";
          }
          {
            type = "cpu";
            key = "├󰻟 CPU";
            keyColor = "green";
          }
          {
            type = "gpu";
            key = "├󰾲 GPU";
            keyColor = "green";
          }
          {
            type = "memory";
            key = "├󰍛 RAM";
            keyColor = "green";
          }
          {
            type = "disk";
            key = "└󰋊 Disk";
            keyColor = "green";
          }
          "break"
          {
            type = "os";
            key = "{icon} OS";
            keyColor = "yellow";
          }
          {
            type = "kernel";
            key = "├󰣇 Kernel";
            keyColor = "yellow";
          }
          {
            type = "bios";
            key = "├󰾻 BIOS";
            keyColor = "yellow";
          }
          {
            type = "packages";
            key = "├󰏖 Packages";
            keyColor = "yellow";
          }
          {
            type = "shell";
            key = "└󰆍 Shell";
            keyColor = "yellow";
          }
          "break"
          {
            type = "de";
            key = "󰍹 DE";
            keyColor = "blue";
          }
          {
            type = "lm";
            key = "├󰷖 LM";
            keyColor = "blue";
          }
          {
            type = "wm";
            key = "├󰖲 WM";
            keyColor = "blue";
          }
          {
            type = "wmtheme";
            key = "├󰉼 WM Theme";
            keyColor = "blue";
          }
          {
            type = "terminal";
            key = "└󰐥 Terminal";
            keyColor = "blue";
          }
          "break"
          {
            type = "command";
            key = "┌󰃰 OS Age ";
            keyColor = "magenta";
            text = "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
          }
          {
            type = "uptime";
            key = "├󰅐 Uptime ";
            keyColor = "magenta";
          }
          {
            type = "datetime";
            key = "└󰃰 DateTime ";
            keyColor = "magenta";
          }
        ];
      };
    };
  };
}
