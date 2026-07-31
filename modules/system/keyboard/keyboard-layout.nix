{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.keyboard-layout;
in
{
  config = lib.mkIf cfg.enable {
    services.xserver.xkb = {
      layout = "us,bg_phonetic_dvorak";
      variant = "dvorak,";
      options = "grp:shifts_toggle";
      extraLayouts.bg_phonetic_dvorak = {
        description = "Bulgarian Phonetic Dvorak";
        languages = [ "bul" ];
        symbolsFile = ./bg-phonetic-dvorak;
      };
    };
  };
}
