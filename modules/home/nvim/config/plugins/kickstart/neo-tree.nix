{ config, lib, ... }:

{
  config.programs.nixvim = {

    # Neo-tree is a Neovim plugin to browse the file system
    # https://nix-community.github.io/nixvim/plugins/neo-tree/index.html?highlight=neo-tree#pluginsneo-treepackage
    plugins.neo-tree = {
      enable = true;

      settings = {
        close_if_last_window = false;

        filesystem = {
          follow_current_file = {
            enable = true;
            leave_dirs_open = true;
          };
          window = {
            mappings = {
              "\\" = "close_window";
            };
          };
        };
      };
    };

    # https://nix-community.github.io/nixvim/keymaps/index.html
    keymaps = [
      {
        key = "\\";
        action = "<cmd>Neotree reveal<cr>";
        options = {
          desc = "NeoTree reveal";
        };
      }
    ];
  };
}
