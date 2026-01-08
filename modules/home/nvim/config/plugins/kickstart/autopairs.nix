{ config, lib, ... }:

{ config.programs.nixvim = {
 
  # Inserts matching pairs of parens, brackets, etc.
  # https://nix-community.github.io/nixvim/plugins/nvim-autopairs/index.html
  plugins.nvim-autopairs = {
    enable = true;
  };
};
}
