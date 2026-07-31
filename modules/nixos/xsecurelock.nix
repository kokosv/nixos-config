{ lib, pkgs, ... }: {
  options.nixos.xsecurelock = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.xsecurelock = {
    environment.systemPackages = with pkgs; [ xsecurelock xss-lock ];
    programs.xss-lock = {
      enable = true;
      lockerCommand = "${pkgs.xsecurelock}/bin/xsecurelock";
    };
  };
}
