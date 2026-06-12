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
        bindkey '^[[C' forward-char
        bindkey '^[[D' backward-char
        bindkey '^@' autosuggest-accept
        bindkey '^[^?' backward-kill-word

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
