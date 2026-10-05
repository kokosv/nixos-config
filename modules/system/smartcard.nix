{ lib, ... }: {
  options.nixos.smartcard = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.smartcard = { pkgs, ... }: {
    services.pcscd.enable = true;
    environment.systemPackages = with pkgs; [
      opensc
      pcsc-tools
      openssl
    ];

    # Firefox's PKCS#11 module registration (opensc-pkcs11.so) lives in
    # modules/home/firefox.nix, not here.

    # Using a B-Trust (BORICA) qualified cert/card. Firefox needs the B-Trust
    # CA chain imported to validate it: Settings -> Privacy & Security ->
    # Certificates -> Manage Certificates -> Authorities -> Import, picking
    # the cert files kept in ./_smartcard/ (skipped by flake.nix's module scan).

    # Diagnostics (reader + card, e.g. Comitex CCR7115B-02 w/ B-Trust card):
    #   pcsc_scan                                                            # confirm reader + card are seen, dumps ATR
    #   pkcs11-tool --module /run/current-system/sw/lib/opensc-pkcs11.so -L  # list slots/tokens
    #   pkcs11-tool --module /run/current-system/sw/lib/opensc-pkcs11.so -O  # list cert/key objects on the card
  };
}
