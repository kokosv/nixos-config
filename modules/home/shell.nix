{ lib, ... }: {
  options.homeManager.shell = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.shell = {
    home.shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";

      r = "ranger";
      c = "clear";

      ssh = "kitten ssh";

      l = "eza";
      ll = "eza -l";
      la = "eza -a";
      lal = "eza -a -l";
      lt = "eza -T -L ";
      lta = "eza -T -a -L ";
      ltl = "eza -T -l -L ";
      ltla = "eza -T -l -a -L ";

      nixreb = "sudo nixos-rebuild --flake ~/.nixos-config#kt480 switch";
      nixbld = "sudo nixos-rebuild build --flake ~/.nixos-config#kt480";
      nixtst = "sudo nixos-rebuild test --flake ~/.nixos-config#kt480";

      kys = "sudo shutdown -h now";

      hdmiup = "xrandr --output HDMI-2 --mode 1920x1080 --above eDP-1";
      hdmir = "xrandr --output HDMI-2 --mode 1920x1080 --right-of eDP-1";
      hdmil = "xrandr --output HDMI-2 --mode 1920x1080 --left-of eDP-1";
    };

    programs.bash = {
      enable = true;
      initExtra = ''

        shopt -s autocd

        export HISTSIZE=1024
        export HISTFILESIZE=4096
        export HISTCONTROL=ignoredups

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

        nixgc_old() {
          if [[ $# -ne 1 ]]; then
            echo "Usage: nixgc_old <7d(ays)>"
            return 1
          fi
          sudo nix-collect-garbage --delete-older-than "$1"
        }

        nixgc_store() {
          sudo nix store gc
        }

        nixgc_opt() {
          sudo nix store optimise
        }

      '';
    };
  };
}
