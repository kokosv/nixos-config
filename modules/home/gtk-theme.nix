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
    home.packages = with pkgs; [
      libsForQt5.qt5ct
      kdePackages.breeze-gtk
      kdePackages.breeze-icons
    ];

    gtk = {
      enable = true;

      theme = {
        name = "Breeze-Dark";
        package = pkgs.kdePackages.breeze-gtk;
      };

      iconTheme = {
        name = "breeze-dark";
        package = pkgs.kdePackages.breeze-icons;
      };

      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;

      gtk4.theme = config.gtk.theme;
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk3";
      style.name = "Breeze";
    };

    xdg.configFile."qt5ct/qt5ct.conf".text = ''
      [Appearance]
      style=Breeze
      custom_palette=false
      color_scheme_path=

      [IconTheme]
      theme=breeze-dark
    '';

    home.sessionVariables = {
      QT_QPA_PLATFORMTHEME = lib.mkForce "qt5ct";
      QT_STYLE_OVERRIDE = "Breeze";
      GTK_THEME = "Breeze-Dark:dark";
      QT_USE_NATIVE_DIALOGS = "0";
      GTK_USE_PORTAL = "1";
    };
  };
}
