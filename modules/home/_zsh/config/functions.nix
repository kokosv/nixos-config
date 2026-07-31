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

  # FZF hook for direnv
  eval "$(direnv hook zsh)"
''
