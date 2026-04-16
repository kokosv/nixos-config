{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home.modules.thunderbird;
in
{
  config = lib.mkIf cfg.enable {
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
