{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.khal;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ khal ];

    xdg.configFile."khal/config".text = ''
     
      [calendars]
        [[mycalendar]]
        path = ~/.config/khal/calendars/mycalendar/
        type = calendar
        color = dark green      
 
      [default]
        default_calendar = mycalendar
        highlight_event_days = true
	show_all_days = false
	timedelta = 90d

      [view]
        agenda_event_format = {calendar-color}{cancelled}{start-end-time-style} {title}{repeat-symbol}{alarm-symbol}{description-separator}{description}{reset}
	dynamic_days = true
	event_view_always_visible = true

      [locale]
        weeknumbers = right
        firstweekday = 0
    '';      
  };
}

