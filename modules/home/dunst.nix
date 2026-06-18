{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.dunst;
  color = "#b2b1ad";
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ dunst ];

    services.dunst = {
      enable = true;

      settings = {
        global = {
          origin = "top-right";
          offset = "5x30";

          font = "DepartureMono Nerd Font 12";
          frame_color = color;
          frame_width = 1;
          progress_bar_horizontal_alignment = "center";
          progress_bar = true;
          progress_bar_height = 4;
          progress_bar_frame_width = 1;
          progress_bar_min_width = 150;

          progress_bar_color = "#b2b1ad";
          progress_bar_frame_color = "#666666";

          enable_recursive_icon_lookup = true;
          icon_theme = lib.mkForce "breeze-dark";
          icon_path = lib.mkForce "/run/current-system/sw/share/icons/";
          icon_position = "left";
          min_icon_size = 32;
          max_icon_size = 32;
          icon_corners = 0;
          icon_corners_radius = 0;

          background = "#000000";
          foreground = color;
          transparency = 0;

          width = 300;

          padding = 5; # vertical
          horizontal_padding = 5; # horizontal
          text_icon_padding = 0;

          corner_radius = 0;

          follow = "none";
          mouse_left_click = "do_action";
          mouse_middle_click = "close_all";
          mouse_right_click = "close_current";

          history_length = 20;
          sticky_history = false;

          browser = "${pkgs.xdg-utils}/bin/xdg-open";
          show_indicators = true;

        };

        # 0 - until dismissed
        urgency_low = {
          background = "#000000";
          foreground = color;
          frame_color = color;
          highlight = color;
          timeout = 2;
        };

        urgency_normal = {
          background = "#000000";
          foreground = color;
          frame_color = "#FFEAA7";
          highlight = color;
          timeout = 4;
        };

        urgency_critical = {
          background = "#000000";
          foreground = color;
          frame_color = "#FF6B6B";
          highlight = color;
          timeout = 6;
        };
      };
    };
  };
}
