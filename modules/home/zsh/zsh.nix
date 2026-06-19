{
  config,
  pkgs,
  ...
}:

let
  zshAliases = import ./config/aliases.nix;
  zshFunctions = import ./config/functions.nix;
  zshPlugins = import ./config/plugins.nix { inherit pkgs; };
in
{
  config = {
    programs.zsh = {
      enable = true;

      enableCompletion = true;

      # disabled integrated for manual adding and configuring the plugin zsh-autosuggestion
      # autosuggestion = {
      #   enable = true;
      #   strategy = [
      #     "history"
      #     "completion"
      #   ];
      # };

      syntaxHighlighting.enable = false; # older and conficts with plugin zsh-plugin-highlighting

      # zprof.enable = true; # debug startup time

      autocd = true;

      history = {
        size = 1024;
        share = true;
        save = 4096;
        path = "${config.xdg.dataHome}/zsh/history"; # ~/.local/state/zsh/history (XDG compliant)
        ignoreAllDups = true;
        extended = true;
      };

      shellAliases = zshAliases;

      plugins = zshPlugins.pluginPackages;

      initContent = ''
        # custom functions
        ${zshFunctions}

        # ============================================
        # Completion styles (BEFORE compinit)
        # ============================================
        zstyle ':completion:*' completer _expand_alias _complete _ignored

        # ============================================
        # fzf-tab config (BEFORE compinit)
        # ============================================
        ${zshPlugins.fzfTabConfig}

        # ============================================
        # compinit runs here (via enableCompletion=true)
        # ============================================

        # ============================================
        # Plugins that wrap widgets (AFTER compinit)
        # ============================================
        # fzf-tab source
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

        # zsh-autosuggestions source
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

        # zsh-wd config (no widget wrapping, safe here)
        ${zshPlugins.wdConfig}

        # ============================================
        # Key bindings
        # ============================================
        # bindkey '^I' expand-or-complete # bash like tab - disabled conflicting with plugin zsh-fzf-tab

        # Right arrow - move cursor one character right
        bindkey '^[[C' forward-char

        # Left arrow - move cursor one character left
        bindkey '^[[D' backward-char

        # Ctrl+Right to move forward one word
        bindkey '^[[1;5C' forward-word

        # Ctrl+Left to move backward one word
        bindkey '^[[1;5D' backward-word

        # Ctrl+Delete to delete forward one word
        bindkey '^[[3;5~' kill-word

        # Ctrl+Backspace to delete backward one word
        bindkey '^H' backward-kill-word

        # Ctrl+Space - accept autosuggestion
        bindkey '^@' autosuggest-accept

        # Disable Ctrl+D (closes terminal)
        setopt IGNORE_EOF

        # Unbind default fzf keybinds
        bindkey -r '^T'     # Remove Ctrl+T (files)
        bindkey -r '^R'     # Remove Ctrl+R (history)
        bindkey -r '^[c'    # Remove Alt+C (directories)

        # Custom fzf keybindings
        bindkey '^F' fzf-file-widget      # Ctrl+F for files
        bindkey '^B' fzf-history-widget   # Ctrl+H for history
        bindkey '^D' fzf-cd-widget        # Ctrl+D for directories

        # ============================================
        # nix-your-shell
        # ============================================
        if [ -f "${pkgs.nix-your-shell}/bin/nix-your-shell" ]; then
          eval "$(${pkgs.nix-your-shell}/bin/nix-your-shell zsh)"
        fi

        source ${./config/prompt.zsh}

        # ============================================
        # Syntax highlighting (MUST BE LAST)
        # ============================================
        ${zshPlugins.syntaxHighlightingConfig}
        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      '';
    };
  };
}
