{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.gtk-theme;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ numix-gtk-theme ];

    gtk = {
      enable = true;

      theme = {
        name = "Breeze-Dark";
        package = pkgs.kdePackages.breeze-gtk;
      };

      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };

      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;

      gtk4.theme = config.gtk.theme;
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk";
      style.name = "gtk2";
    };

  };
}
