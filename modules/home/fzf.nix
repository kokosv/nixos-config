{ lib, ... }: {
  options.homeManager.fzf = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.fzf = { pkgs, ... }: {
    home.packages = with pkgs; [ fzf ];

    programs.fzf = {
      enable = true;
      # enableBashIntegration = true;
      enableZshIntegration = true;

      defaultOptions = [
        "--style minimal"
        "--height 40%"
        "--layout reverse"
        "--bind ctrl-j:down"
        "--bind ctrl-k:up"
        #"--preview 'cat {}'"
      ];
    };
  };
}
