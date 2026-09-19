{ lib, ... }: {
  options.nixos.sshServer = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.sshServer = {
    services.openssh = {
      enable = true;
      # ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
        ChallengeResponseAuthentication = false;
        UsePAM = false;
        AllowUsers = [ "koko" ];
      };
    };
  };
}
