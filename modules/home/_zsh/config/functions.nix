''
  # Git: add all, commit with message, push
  gitfkit() {
    git add .
    git commit -m "$1"
    git push
  }

  # Show directory sizes sorted
  sdir() {
    if [ "$#" -ne 2 ]; then
      echo "Usage: sdir <level> <dir>"
      return 1
    fi
    local level=$1
    local dir=$2
    du -h --max-depth="$level" "$dir" | sort -hr
  }

  # Nix: collect garbage older than X days
  nixgc_old() {
    if [[ $# -ne 1 ]]; then
      echo "Usage: nixgc_old <7d(ays)>"
      return 1
    fi
    sudo nix-collect-garbage --delete-older-than "$1"
  }

  # Nix: garbage collect store
  nixgc_store() {
    sudo nix store gc
  }

  # Nix: optimise store
  nixgc_opt() {
    sudo nix store optimise
  }

  # Random hex string (defaults to 32 bytes)
  passrnd() {
    local n=''${1:-32}
    openssl rand -hex "$n"
  }

  # Rebuild a NixOS host by name
  nixreb() {
    case "$1" in
      kt480)
        sudo nixos-rebuild --flake ~/.nixos-config#kt480 switch
        ;;
      klegion)
        echo "klegion: not configured yet"
        ;;
      vps)
        sudo nixos-rebuild switch --flake ~/.nixos-config#vps --target-host root@31.70.105.226
        ;;
      homeserver)
        sudo nixos-rebuild switch --flake ~/.nixos-config#homeserver --target-host root@100.64.0.5
        ;;
      *)
        echo "Usage: nixreb <kt480|klegion|vps|homeserver>"
        ;;
    esac
  }

  # FZF hook for direnv
  eval "$(direnv hook zsh)"
''
