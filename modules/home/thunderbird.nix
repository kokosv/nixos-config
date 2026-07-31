{ lib, ... }: {
  options.homeManager.thunderbird = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.thunderbird = { pkgs, ... }: {
    home.packages = with pkgs; [ thunderbird ];

    programs.thunderbird = {
      enable = true;
      profiles."default" = {
        isDefault = true;
        # withExternalGnupg = true;
      };
      # settings = {
      #   "mail.openpgp.allow_external_gnupg" = true;
      #   "mail.openpgp.fetch_pubkeys_from_gnupg" = true;
      # };
    };
  };
}
