{ config, pkgs, lib, ... }:

let
  cfg = config.home.modules.shell;
in {
  config = lib.mkIf cfg.enable {
    home.shellAliases = {
 
      ".." = "cd ..";
      "..." = "cd ../..";
      
      r = "ranger";
      c = "clear";
      
      l = "eza";
      ll = "eza -l";
      la = "eza -a";
      lal = "eza -a -l";
      lt = "eza -T -L ";
      lta = "eza -T -a -L ";
      ltl = "eza -T -l -L ";
      ltla = "eza -T -l -a -L ";

      nixreb = "sudo nixos-rebuild --flake ~/.nixos-config#kt480 switch";
      kys = "sudo shutdown -h now";
      lock = "sudo systemctl restart greetd"; 
    };

    programs.bash = {
      enable = true;
      initExtra = ''

        gitfkit() {
          git add .
          git commit -m "$1"
          git push
        }

        sdir() {
          if [ "$#" -ne 2 ]; then
	      echo "Usage: sdir <level> <dir>"
              return 1
          fi
          level=$1
          dir=$2
          du -h --max-depth="$level" "$dir" | sort -hr
        }

        nixclr() {
	  if [ "$#" -ne 1 ]; then
	      echo "Usage: nixclr <days>"
	      return 1
	  fi
	  days=$1
	  nix-collect-garbage --delete-older-than "$days"
	}
	
	shopt -s autocd

        export HISTSIZE=1024
	export HISTFILESIZE=4096
	export HISTCONTROL=ignoredups

	eval "$(direnv hook bash)"
      '';
    };
  };
}
