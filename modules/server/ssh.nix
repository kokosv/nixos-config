{ lib, ... }: {
  options.server.ssh = lib.mkOption { type = lib.types.deferredModule; };

  config.server.ssh = {
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
