{ lib, ... }: {
  options.vps.ssh = lib.mkOption { type = lib.types.deferredModule; };

  config.vps.ssh = {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "yes";
        KbdInteractiveAuthentication = false;
        ChallengeResponseAuthentication = false;
      };
    };
  };
}
