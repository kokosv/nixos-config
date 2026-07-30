{ config, pkgs, lib, ... }:

let
  cfg = config.modules.ssh-server;
in {
  config = lib.mkIf cfg.enable {
    # ssh server (accepting requests) // ssh client (making requests) in a home module
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
