{ lib, ... }: {
  options.homeManager.sshClient = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.sshClient = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      # matchBlocks."*"
    };
  };
}
