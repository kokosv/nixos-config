{ lib, ... }: {
  options.nixos.keyboardLayout = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.keyboardLayout = {
    services.xserver.xkb = {
      layout = "us,bg_phonetic_dvorak";
      variant = "dvorak,";
      options = "grp:super_space_toggle";
      extraLayouts.bg_phonetic_dvorak = {
        description = "Bulgarian Phonetic Dvorak";
        languages = [ "bul" ];
        symbolsFile = ./_keyboard/bg-phonetic-dvorak;
      };
    };
  };
}
