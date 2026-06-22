{ config, lib, ... }:

{
  config.programs.nixvim = {

    # Neo-tree is a Neovim plugin to browse the file system
    # https://nix-community.github.io/nixvim/plugins/neo-tree/index.html?highlight=neo-tree#pluginsneo-treepackage
    plugins.neo-tree = {
      enable = true;

      settings = {

        open_files_do_not_replace_types = [ ];

        close_if_last_window = false;
        open_files_in_last_window = true;

        filesystem = {
          follow_current_file = {
            enabled = true;
            leave_dirs_open = true;
          };

          use_libuv_file_watcher = true;

          window = {
            position = "left";
            width = 40;
            auto_expand_width = false;
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
