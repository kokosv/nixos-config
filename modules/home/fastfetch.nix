{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.fastfetch;
in
{
  config = lib.mkIf cfg.enable {
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
            key = "├";
            keyColor = "green";
          }
          {
            type = "gpu";
            key = "├󰍛";
            keyColor = "green";
          }
          {
            type = "memory";
            key = "├󰍛";
            keyColor = "green";
          }
          {
            type = "disk";
            key = "└";
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
            key = "├";
            keyColor = "yellow";
          }
          {
            type = "bios";
            key = "├";
            keyColor = "yellow";
          }
          {
            type = "packages";
            key = "├󰏖";
            keyColor = "yellow";
          }
          {
            type = "shell";
            key = "└";
            keyColor = "yellow";
          }
          "break"
          {
            type = "de";
            key = " DE";
            keyColor = "blue";
          }
          {
            type = "lm";
            key = "├";
            keyColor = "blue";
          }
          {
            type = "wm";
            key = "├";
            keyColor = "blue";
          }
          {
            type = "wmtheme";
            key = "├󰉼";
            keyColor = "blue";
          }
          {
            type = "terminal";
            key = "└";
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
