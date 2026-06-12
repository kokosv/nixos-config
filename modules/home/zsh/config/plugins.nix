{ pkgs }:

{
  pluginPackages = with pkgs; [
    {
      name = "zsh-completions";
      src = zsh-completions;
    }
    {
      name = "zsh-autosuggestions";
      src = zsh-autosuggestions;
    }
    {
      name = "zsh-syntax-highlighting";
      src = zsh-syntax-highlighting;
    }
    {
      name = "zsh-nix-shell";
      src = zsh-nix-shell;
    }
    {
      name = "zsh-wd";
      src = zsh-wd;
      file = "share/wd/wd.plugin.zsh";
      functions = [ "share/zsh/site-functions" ];
    }
    {
      name = "fzf-tab";
      src = zsh-fzf-tab;
      file = "share/fzf-tab/fzf-tab.plugin.zsh";
    }
  ];

  autosuggestionsConfig = ''
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  '';

  syntaxHighlightingConfig = ''
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

    typeset -A ZSH_HIGHLIGHT_STYLES

    # Stop coloring valid commands green
    ZSH_HIGHLIGHT_STYLES[command]='none'
    ZSH_HIGHLIGHT_STYLES[hashed-command]='none'
    ZSH_HIGHLIGHT_STYLES[arg0]='none'
    ZSH_HIGHLIGHT_STYLES[alias]='fg=white,bold'
    ZSH_HIGHLIGHT_STYLES[builtin]='none'
    ZSH_HIGHLIGHT_STYLES[function]='none'

    # Stop underlining filepaths and color them
    ZSH_HIGHLIGHT_STYLES[path]='none'
    ZSH_HIGHLIGHT_STYLES[path_prefix]='none'
    ZSH_HIGHLIGHT_STYLES[path_approx]='none'
    ZSH_HIGHLIGHT_STYLES[path_pathsep]='none'
    ZSH_HIGHLIGHT_STYLES[path_directory]='none'


    # Ensure invalid/missing commands turn red
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold' 
  '';

  wdConfig = ''
    # Enable directory stack for wd
    setopt AUTO_PUSHD

    # ctrl-b to open the fzf browser
    bindkey '^W' wd_browse_widget
  '';

  fzfTabConfig = ''
    # Disable default menu
    zstyle ':completion:*' menu no

    # Descriptions format
    zstyle ':completion:*:descriptions' format '[%d]'

    # Colorize completions
    zstyle ':completion:*' list-colors ${pkgs.zsh-fzf-tab}/bin/fzf-tab.zsh

    # Fzf flags (optional)
    zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept

    # Preview directory contents
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 $realpath'

    # Switch groups with < and >
    zstyle ':fzf-tab:*' switch-group '<' '>'
  '';
}
