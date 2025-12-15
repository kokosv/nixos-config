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

      # connect monitor settings
      hdmiup = "xrandr --output HDMI-2 --mode 1920x1080 --above eDP-1";
      hdmir = "xrandr --output HDMI-2 --mode 1920x1080 --right-of eDP-1";
      hdmil = "xrandr --output HDMI-2 --mode 1920x1080 --left-of eDP-1";
      
      # add lock screen
      # lock = "";

    };

    programs.bash = {
      enable = true;
      initExtra = ''
 
        # direct usage of dir names - skip cd
	shopt -s autocd

        # command history
        export HISTSIZE=1024
	export HISTFILESIZE=4096
	export HISTCONTROL=ignoredups

        # fzf hook
	eval "$(direnv hook bash)"

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

	nixgc() {
	    if [[ $# -ne 1 ]]; then
		echo "Usage: nixgc <7d(ays)>"
		return 1
	    fi

	    local interval="$1"

	    run_step() {
		local cmd="$1"
		local description="$2"

		echo -e "\n=== $description ==="
		eval "$cmd"
		local rc=$?

		if (( rc != 0 )); then
		    echo -e "\n❌  $description failed (exit code $rc). Stopping the chain."
		    return $rc
		else
		    echo "✅  $description succeeded."
		fi
	    }

	    run_step "sudo nix-collect-garbage --delete-older-than \"$interval\"" \
		     "Garbage‑collect old generations (older than $interval)" || return $?
	    run_step "sudo nix store gc" \
		     "Store garbage collection (remove unreferenced paths)" || return $?
	    run_step "sudo nix store optimise" \
		     "Store optimisation (deduplicate existing data)" || return $?

	    echo -e "\n🎉  All three steps completed successfully."
	}

      '';
    };
  };
}
