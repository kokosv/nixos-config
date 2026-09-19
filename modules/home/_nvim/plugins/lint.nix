{
  config,
  lib,
  pkgs,
  ...
}:

{
  config.programs.nixvim = {

    extraPackages = with pkgs; [
      markdownlint-cli
      hadolint
      checkstyle
    ];

    # Linting
    # https://nix-community.github.io/nixvim/plugins/lint/index.html
    plugins.lint = {
      enable = true;

      # NOTE: Enabling these will cause errors unless these tools are installed
      lintersByFt = {
        nix = [ "nix" ];
        markdown = [
          "markdownlint"
        ];
        dockerfile = [ "hadolint" ];
        java = [ "checkstyle" ];
      };

      # Create autocommand which carries out the actual linting
      # on the specified events.
      autoCmd = {
        callback.__raw = ''
          function()
            -- Only run the linter in buffers that you can modify in order to
            -- avoid superfluous noise, notably within the handy LSP pop-ups that
            -- describe the hovered symbol using Markdown.
            if vim.opt_local.modifiable:get() then
              require('lint').try_lint()
            end
          end
        '';
        group = "lint";
        event = [
          "BufEnter"
          "BufWritePost"
          "InsertLeave"
        ];
      };
    };

    # https://nix-community.github.iautoGroupso/nixvim/NeovimOptions/autoGroups/index.html
    autoGroups = {
      lint = {
        clear = true;
      };
    };
  };
}
